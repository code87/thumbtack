defmodule Thumbtack.MultipleImageUploadsTest do
  alias Thumbtack.ImageUpload
  alias Thumbtack.Album

  use Thumbtack.TestCase

  defmodule AlbumPhoto do
    @behaviour Thumbtack.ImageUpload

    use Thumbtack.ImageUpload,
      belongs_to: {:album, Album},
      foreign_key: :album_id,
      schema: "album_photos",
      max_images: 3

    @impl true
    def get_path(album_id, photo_id, %{index: index, style: style}) do
      "/#{album_id}/#{index}/#{photo_id}-#{style}.jpg"
    end

    @impl true
    def styles do
      [
        original: [:square]
      ]
    end
  end

  setup do
    album = insert(:album)
    {:ok, album: album}
  end

  describe "upload(module, owner, src_path, args)" do
    test "uploads image of the given index; accepts owner id", %{album: album} do
      %Album{id: album_id} = album

      assert {:ok, %AlbumPhoto{album_id: ^album_id} = _image_upload,
              %{original: _original_url} = _urls} =
               ImageUpload.upload(AlbumPhoto, album_id, "test/fixtures/photo-small.jpg", %{index: 1})
    end

    test "returns error if upload fails", %{album: album} do
      assert {:error, _message} =
               ImageUpload.upload(AlbumPhoto, album, "test/fixtures/photo-unknown.jpg", %{index: 1})
    end

    test "returns error on invalid index", %{album: album} do
      assert {:error, :index_out_of_bounds} =
               ImageUpload.upload(AlbumPhoto, album, "test/fixtures/photo-unknown.jpg", %{index: 3})
    end
  end

  describe "get_url(module, owner, opts)" do
    test "returns an image url for a given style", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      assert "http://localhost:4000/uploads/#{album.id}/1/#{photo_id}-original.jpg" ==
               ImageUpload.get_url(AlbumPhoto, album, %{index: 1, style: :original})
    end

    test "default style if original", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      assert "http://localhost:4000/uploads/#{album.id}/1/#{photo_id}-original.jpg" ==
               ImageUpload.get_url(AlbumPhoto, album, %{index: 1})
    end

    test "default index is 0", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album)

      assert "http://localhost:4000/uploads/#{album.id}/0/#{photo_id}-original.jpg" ==
               ImageUpload.get_url(AlbumPhoto, album)
    end

    test "returns nil if image not found", %{album: album} do
      assert is_nil(ImageUpload.get_url(AlbumPhoto, album))
    end
  end

  describe "delete(module, owner, opts)" do
    test "deletes image upload", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      assert {:ok, %AlbumPhoto{id: ^photo_id, index_number: 1}} =
               ImageUpload.delete(AlbumPhoto, album, %{index: 1})
    end

    test "default index is 0", %{album: album} do
      {:ok, %AlbumPhoto{id: photo_id}} = AlbumPhoto.create_image_upload(album, %{index: 0})

      assert {:ok, %AlbumPhoto{id: ^photo_id, index_number: 0}} =
               ImageUpload.delete(AlbumPhoto, album)
    end

    test "returns error tuple if image not found", %{album: album} do
      assert {:error, :not_found} = ImageUpload.delete(AlbumPhoto, album, %{index: 1})
    end

    test "returns error tuple on invalid index", %{album: album} do
      assert {:error, :not_found} = ImageUpload.delete(AlbumPhoto, album, %{index: 3})
    end
  end
end
