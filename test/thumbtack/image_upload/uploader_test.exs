defmodule Thumbtack.ImageUpload.UploaderTest do
  alias Thumbtack.ImageUpload.Style
  alias Thumbtack.ImageUpload.Uploader
  alias Thumbtack.{User, Utils}

  alias Vix.Vips

  use Thumbtack.TestCase

  defmodule UserPhoto do
    @behaviour Thumbtack.ImageUpload

    alias Thumbtack.User

    use Thumbtack.ImageUpload,
      foreign_key: :user_id

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "user_photos" do
      belongs_to(:user, User)
      field(:last_updated_at, :utc_datetime)
    end

    @impl true
    def path_prefix(user_id, photo_id, %{style: style}) do
      "/#{user_id}/#{photo_id}-#{style}"
    end

    @impl true
    def styles do
      [
        original: [:square, {:resize, 256}],
        thumb: [{:thumbnail, size: 64, source: :original}]
      ]
    end
  end

  def uploader_with_styles(src_path \\ "") do
    Uploader.new(
      module: UserPhoto,
      src_path: src_path,
      styles: [
        original: [:square, {:resize, 256}],
        thumb: [{:thumbnail, size: 64, source: :original}]
      ]
    )
  end

  describe "validate_args(uploader)" do
    test "validates index for single image uploads" do
      defmodule SingleImage do
        use Thumbtack.ImageUpload,
          belongs_to: {:user, User},
          foreign_key: :user_id,
          schema: "user_photos"
      end

      assert {:error, :index_out_of_bounds, _uploader} =
               Uploader.new(index: 1, module: SingleImage) |> Uploader.validate_args()

      assert {:error, :index_out_of_bounds, _uploader} =
               Uploader.new(index: -1, module: SingleImage) |> Uploader.validate_args()
    end

    test "validates index for multiple images uploads" do
      defmodule MultipleImages do
        use Thumbtack.ImageUpload,
          belongs_to: {:album, Album},
          foreign_key: :album_id,
          schema: "album_photos",
          max_images: 3
      end

      uploader = Uploader.new(index: 3, module: MultipleImages)

      assert {:error, :index_out_of_bounds, _uploader} = Uploader.validate_args(uploader)
    end
  end

  describe "maybe_download_image(uploader)" do
    test "downloads image to temp folder, updates src_path" do
      uploader = Uploader.new(src_path: "https://example.com/photo-small.jpg")

      assert %Uploader{src_path: src_path} = Uploader.maybe_download_image(uploader)
      assert String.starts_with?(src_path, System.tmp_dir())
      assert File.exists?(src_path)
    end

    test "returns error if request fails" do
      uploader = Uploader.new(src_path: "https://example.com/photo-unknown.jpg")

      assert {:error, _message, _uploader} = Uploader.maybe_download_image(uploader)
    end

    test "returns unchanged uploader if src_path is local" do
      uploader = Uploader.new(src_path: "test/fixtures/photo-small.jpg")

      assert %Uploader{src_path: "test/fixtures/photo-small.jpg"} =
               Uploader.maybe_download_image(uploader)
    end
  end

  describe "validate_image(uploader_or_error)" do
    test "returns unchanged uploader if valid image file exists at src_path" do
      uploader = Uploader.new(src_path: "test/fixtures/photo-small.jpg")

      assert %Uploader{src_path: "test/fixtures/photo-small.jpg"} =
               Uploader.validate_image(uploader)
    end

    test "returns error if image file is invalid" do
      uploader = Uploader.new(src_path: "test/fixtures/corrupted.jpg")

      assert {:error, _message, %Uploader{}} = Uploader.validate_image(uploader)
    end

    test "returns error if file does not exist" do
      uploader = Uploader.new(src_path: "test/fixtures/photo-unknown.jpg")

      assert {:error, _message, %Uploader{}} = Uploader.validate_image(uploader)
    end

    test "forwards error" do
      uploader = Uploader.new(src_path: "/some/path")

      assert {:error, :fail, %Uploader{src_path: "/some/path"}} =
               Uploader.validate_image({:error, :fail, uploader})
    end
  end

  describe "process_styles(uploader_or_error)" do
    test "processes image styles one by one and updates uploader state" do
      uploader = uploader_with_styles("test/fixtures/photo-small.jpg")

      assert %Uploader{
               module: UserPhoto,
               state: %{
                 original: %Style{image: %Vips.Image{} = original_image, path: original_path},
                 thumb: %Style{image: %Vips.Image{} = thumb_image, path: thumb_path}
               }
             } = Uploader.process_styles(uploader)

      assert File.exists?(original_path)
      assert 128 == Vips.Image.width(original_image)
      assert 128 == Vips.Image.height(original_image)

      assert File.exists?(thumb_path)
      assert 64 == Vips.Image.width(thumb_image)
      assert 64 == Vips.Image.height(thumb_image)
    end

    test "returns error if style processing failed" do
      uploader = uploader_with_styles("test/fixtures/photo-unknown.jpg")

      assert {:error, _term, _uploader} = Uploader.process_styles(uploader)
    end

    test "forwards error" do
      uploader = Uploader.new(src_path: "/some/path")

      assert {:error, :fail, %Uploader{src_path: "/some/path"}} =
               Uploader.process_styles({:error, :fail, uploader})
    end
  end

  describe "get_or_create_image_upload(uploader_or_error)" do
    test "creates image upload entity for owner, if does not exist" do
      user = insert(:user)

      uploader = Uploader.new(module: UserPhoto, owner: user)

      assert %{image_upload: %UserPhoto{}} = Uploader.get_or_create_image_upload(uploader)
    end

    test "updates uploader with existing image upload entity" do
      user = insert(:user)
      {:ok, %UserPhoto{id: image_upload_id}} = UserPhoto.create_image_upload(user)

      uploader = Uploader.new(module: UserPhoto, owner: user)

      assert %{image_upload: %UserPhoto{id: ^image_upload_id}} =
               Uploader.get_or_create_image_upload(uploader)
    end

    test "[PENDING] constraint violation due to race condition" do
    end

    test "forwards error" do
      uploader = Uploader.new(src_path: "/some/path")

      assert {:error, :fail, %Uploader{src_path: "/some/path"}} =
               Uploader.get_or_create_image_upload({:error, :fail, uploader})
    end
  end

  describe "put_to_storage(uploader_or_error)" do
    test "uploads style images to storage" do
      uploader =
        Uploader.new(
          module: UserPhoto,
          owner: %User{id: 123},
          state: %{
            original: %{path: "test/fixtures/photo-wide.jpg"},
            thumb: %{path: "test/fixtures/photo-small.jpg"}
          },
          image_upload: %UserPhoto{user_id: 123, id: "54321-abcde"}
        )

      assert %Uploader{
               state: %{
                 original: %{url: "http://localhost:4000/uploads/123/54321-abcde-original.png"},
                 thumb: %{url: "http://localhost:4000/uploads/123/54321-abcde-thumb.png"}
               }
             } = Uploader.put_to_storage(uploader)
    end

    test "returns error if upload fails" do
    end

    test "forwards error" do
      uploader = Uploader.new(src_path: "/some/path")

      assert {:error, :fail, %Uploader{src_path: "/some/path"}} =
               Uploader.put_to_storage({:error, :fail, uploader})
    end
  end

  describe "verify(result_or_error)" do
    test "wraps successful upload result" do
      timestamp = Utils.timestamp()

      uploader =
        Uploader.new(
          image_upload: %UserPhoto{
            id: "54321-abcde",
            user_id: 123,
            last_updated_at: timestamp
          },
          state: %{
            original: %{url: "http://localhost:4000/uploads/123/54321-abcde-original.jpg"},
            thumb: %{url: "http://localhost:4000/uploads/123/54321-abcde-thumb.jpg"}
          }
        )

      expected_timestamp = DateTime.utc_now() |> DateTime.to_unix()

      expected_original_url =
        "http://localhost:4000/uploads/123/54321-abcde-original.jpg?v=#{expected_timestamp}"

      expected_thumb_url =
        "http://localhost:4000/uploads/123/54321-abcde-thumb.jpg?v=#{expected_timestamp}"

      assert {:ok, %UserPhoto{id: "54321-abcde", user_id: 123, last_updated_at: ^timestamp},
              %{
                original: ^expected_original_url,
                thumb: ^expected_thumb_url
              }} = Uploader.verify(uploader)
    end

    test "returns error on fail" do
      uploader = Uploader.new()

      assert {:error, :fail} = Uploader.verify({:error, :fail, uploader})
    end
  end
end
