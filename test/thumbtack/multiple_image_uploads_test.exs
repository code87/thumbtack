defmodule Thumbtack.MultipleImageUploadsTest do
  alias Thumbtack.Album

  use Thumbtack.TestCase

  defmodule AlbumPhoto do
    @behaviour Thumbtack.ImageUpload

    use Thumbtack.ImageUpload,
      foreign_key: :album_id,
      format: :jpg,
      max_images: 3

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "album_photos" do
      belongs_to(:album, Album)
      field(:index_number, :integer, default: 0)
      field(:last_updated_at, :utc_datetime)
    end

    @impl true
    def path_prefix(album_id, photo_id, %{index: index, style: style}) do
      "/#{album_id}/#{index}/#{photo_id}-#{style}"
    end

    @impl true
    def styles do
      [
        original: [:square],
        sm: [:square, {:resize, 256}]
      ]
    end
  end

  setup do
    album = insert(:album)
    {:ok, album: album}
  end

  describe "upload(module, src_path, args)" do
    test "uploads image of the given index; accepts owner id", %{album: album} do
      %Album{id: album_id} = album

      assert {:ok, %AlbumPhoto{album_id: ^album_id} = _image_upload,
              %{original: _original_url} = _urls} =
               AlbumPhoto.upload(album_id, "test/fixtures/photo-small.jpg", index: 1)
    end

    test "returns error if upload fails", %{album: album} do
      assert {:error, _message} =
               AlbumPhoto.upload(album, "test/fixtures/photo-unknown.jpg", %{index: 1})
    end

    test "returns error on invalid index", %{album: album} do
      assert {:error, :index_out_of_bounds} =
               AlbumPhoto.upload(album, "test/fixtures/photo-small.jpg", index: 3)
    end
  end

  describe "get_url(owner, args)" do
    test "returns an image url for a given style", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      timestamp = DateTime.utc_now() |> DateTime.to_unix()

      assert "http://localhost:4000/uploads/#{album.id}/1/#{photo_id}-original.jpg?v=#{timestamp}" ==
               AlbumPhoto.get_url(album, index: 1, style: :original)
    end

    test "default style if original", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, index: 1)

      timestamp = DateTime.utc_now() |> DateTime.to_unix()

      assert "http://localhost:4000/uploads/#{album.id}/1/#{photo_id}-original.jpg?v=#{timestamp}" ==
               AlbumPhoto.get_url(album, %{index: 1})
    end

    test "default index is 0", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album)

      timestamp = DateTime.utc_now() |> DateTime.to_unix()

      assert "http://localhost:4000/uploads/#{album.id}/0/#{photo_id}-original.jpg?v=#{timestamp}" ==
               AlbumPhoto.get_url(album)
    end

    test "returns nil if image not found", %{album: album} do
      assert is_nil(AlbumPhoto.get_url(album))
    end
  end

  describe "delete(owner, opts)" do
    test "deletes image upload", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}, _} =
        AlbumPhoto.upload(album.id, "test/fixtures/photo-small.jpg", index: 1)

      directory_path =
        Thumbtack.storage().storage_path() <> "/#{album.id}/1"

      assert {:ok, %AlbumPhoto{id: ^photo_id, index_number: 1}} =
               AlbumPhoto.delete(album, %{index: 1})

      refute Path.dirname(directory_path) |> File.exists?()
    end

    test "default index is 0", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}, _} =
        AlbumPhoto.upload(album.id, "test/fixtures/photo-small.jpg")

      directory_path =
        Thumbtack.storage().storage_path() <> "/#{album.id}/0"

      assert {:ok, %AlbumPhoto{id: ^photo_id, index_number: 0}} =
               AlbumPhoto.delete(album)

      refute Path.dirname(directory_path) |> File.exists?()
    end

    test "returns error tuple if image not found", %{album: album} do
      assert {:error, :not_found} = AlbumPhoto.delete(album, index: 1)
    end

    test "returns error tuple on invalid index", %{album: album} do
      assert {:error, :not_found} = AlbumPhoto.delete(album, %{index: 3})
    end

    test "delete original and shifts other images", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id_1}, _} =
        AlbumPhoto.upload(album.id, "test/fixtures/photo-small.jpg", index: 0)

      {:ok, %AlbumPhoto{id: photo_id_2}, _} =
        AlbumPhoto.upload(album.id, "test/fixtures/photo-wide.jpg", index: 1)

      {:ok, %AlbumPhoto{id: photo_id_3}, _} =
        AlbumPhoto.upload(album.id, "test/fixtures/photo-tall.png", index: 2)

      assert {:ok, %AlbumPhoto{id: ^photo_id_1, index_number: 0}} =
               AlbumPhoto.delete(album, %{index: 0})

      assert File.exists?(Thumbtack.storage().storage_path() <> "/#{album.id}/0")
      assert File.exists?(Thumbtack.storage().storage_path() <> "/#{album.id}/1")
      refute File.exists?(Thumbtack.storage().storage_path() <> "/#{album.id}/2")

      assert Path.wildcard(Thumbtack.storage().storage_path() <> "/#{album.id}/0/*") == [
               Thumbtack.storage().storage_path() <> "/#{album.id}/0/#{photo_id_2}-original.jpg",
               Thumbtack.storage().storage_path() <> "/#{album.id}/0/#{photo_id_2}-sm.jpg"
             ]

      assert Path.wildcard(Thumbtack.storage().storage_path() <> "/#{album.id}/1/*") == [
               Thumbtack.storage().storage_path() <> "/#{album.id}/1/#{photo_id_3}-original.jpg",
               Thumbtack.storage().storage_path() <> "/#{album.id}/1/#{photo_id_3}-sm.jpg"
             ]
    end
  end
end
