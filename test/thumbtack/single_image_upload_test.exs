defmodule Thumbtack.SingleImageUploadTest do
  alias Thumbtack.ImageUpload
  alias Thumbtack.User

  use Thumbtack.TestCase

  defmodule UserPhoto do
    @behaviour Thumbtack.ImageUpload

    use Thumbtack.ImageUpload,
      belongs_to: {:user, User},
      foreign_key: :user_id,
      schema: "user_photos"

    @impl true
    def get_path(user_id, photo_id, args) do
      style = Keyword.fetch!(args, :style)

      "/#{user_id}/#{photo_id}-#{style}.jpg"
    end

    @impl true
    def styles do
      [
        original: [:square, {:resize, 256}],
        thumb: [{:thumbnail, size: 64, source: :original}]
      ]
    end
  end

  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  describe "upload(module, owner, src_path)" do
    test "implements image upload workflow; accepts owner id", %{user: user} do
      %User{id: user_id} = user

      assert {:ok, %UserPhoto{user_id: ^user_id} = _image_upload,
              %{original: _original_url, thumb: _thumb_url} = _urls} =
               ImageUpload.upload(UserPhoto, user_id, "test/fixtures/photo-small.jpg")
    end

    test "returns error if upload fails", %{user: user} do
      assert {:error, _message} =
               ImageUpload.upload(UserPhoto, user, "test/fixtures/photo-unknown.jpg")
    end
  end

  describe "get_url(module, owner, args)" do
    test "returns an image url for a given style", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert "http://localhost:4000/uploads/#{user.id}/#{photo_id}-thumb.jpg" ==
               ImageUpload.get_url(UserPhoto, user, style: :thumb)
    end

    test "default style if original", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert "http://localhost:4000/uploads/#{user.id}/#{photo_id}-original.jpg" ==
               ImageUpload.get_url(UserPhoto, user)
    end

    test "returns nil if image not found", %{user: user} do
      assert is_nil(ImageUpload.get_url(UserPhoto, user))
    end
  end

  describe "delete(module, owner)" do
    test "deletes image upload", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert {:ok, %UserPhoto{id: ^photo_id}} = ImageUpload.delete(UserPhoto, user)
    end

    test "returns error tuple if image not found", %{user: user} do
      assert {:error, :not_found} = ImageUpload.delete(UserPhoto, user)
    end
  end
end
