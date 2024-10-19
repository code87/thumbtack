defmodule Thumbtack.ImageUpload.MultipleImagesSchemaTest do
  alias Thumbtack.Album

  use Thumbtack.TestCase

  defmodule AlbumPhoto do
    use Thumbtack.ImageUpload,
      foreign_key: :album_id,
      max_images: 3

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "album_photos" do
      belongs_to :album, Album
      field :index_number, :integer, default: 0
    end
  end

  describe "__using__(opts)" do
    test "validates max_images" do
      assert_raise ArgumentError, fn ->
        defmodule ZeroImages do
          use Thumbtack.ImageUpload,
            belongs_to: {:album, Album},
            foreign_key: :album_id,
            schema: "album_photos",
            max_images: 0
        end
      end

      assert_raise ArgumentError, fn ->
        defmodule TooManyImages do
          use Thumbtack.ImageUpload,
            belongs_to: {:album, Album},
            foreign_key: :album_id,
            schema: "album_photos",
            max_images: 10_001
        end
      end
    end
  end

  def create_album(_context) do
    album = insert(:album)
    {:ok, album: album}
  end

  describe "create_image_upload(owner_or_id, opts)" do
    setup :create_album

    test "creates image upload for a given index", %{album: album} do
      assert {:ok, %AlbumPhoto{index_number: 1}} =
               AlbumPhoto.create_image_upload(album, %{index: 1})
    end

    test "default index is 0; accepts owner id", %{album: album} do
      %{id: album_id} = album
      assert {:ok, %AlbumPhoto{index_number: 0}} = AlbumPhoto.create_image_upload(album_id)
    end

    test "validates index", %{album: album} do
      assert {:error, _changeset} = AlbumPhoto.create_image_upload(album, %{index: 3})
    end
  end

  describe "get_image_upload(owner_or_id, opts)" do
    setup :create_album

    test "returns image upload for a given index", %{album: album} do
      {:ok, %AlbumPhoto{id: image_upload_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      assert %AlbumPhoto{
               id: ^image_upload_id,
               index_number: 1
             } = AlbumPhoto.get_image_upload(album, %{index: 1})
    end

    test "returns nil if image upload does not exist for a given owner", %{album: album} do
      assert is_nil(AlbumPhoto.get_image_upload(album, %{index: 1}))
    end

    test "default index is 0", %{album: album} do
      assert is_nil(AlbumPhoto.get_image_upload(album))
    end

    test "returns nil if index is out of range", %{album: album} do
      assert is_nil(AlbumPhoto.get_image_upload(album, %{index: -1}))
      assert is_nil(AlbumPhoto.get_image_upload(album, %{index: 3}))
    end
  end

  describe "get_or_create_image_upload(owner_or_id, opts)" do
    setup :create_album

    test "returns existing image upload for a given index", %{album: album} do
      {:ok, %AlbumPhoto{id: image_upload_id}} = AlbumPhoto.create_image_upload(album, %{index: 1})

      assert %AlbumPhoto{
               id: ^image_upload_id
             } = AlbumPhoto.get_or_create_image_upload(album, %{index: 1})
    end

    test "default index is 0", %{album: album} do
      {:ok, %AlbumPhoto{id: image_upload_id}} = AlbumPhoto.create_image_upload(album, %{index: 0})

      assert %AlbumPhoto{
               id: ^image_upload_id,
               index_number: 0
             } = AlbumPhoto.get_or_create_image_upload(album)
    end

    test "creates new image upload, if one does not exist; accepts owner id", %{album: album} do
      %{id: album_id} = album

      assert %AlbumPhoto{index_number: 2} =
               AlbumPhoto.get_or_create_image_upload(album_id, %{index: 2})
    end
  end

  describe "delete_image_upload(struct)" do
    setup :create_album

    test "deletes image upload (index not needed)", %{album: album} do
      {:ok, %{id: image_upload_id} = image_upload} =
        AlbumPhoto.create_image_upload(album, %{index: 1})

      assert {:ok, %AlbumPhoto{id: ^image_upload_id}} =
               AlbumPhoto.delete_image_upload(image_upload)

      refute AlbumPhoto.get_image_upload(album, %{index: 1})
    end
  end
end
