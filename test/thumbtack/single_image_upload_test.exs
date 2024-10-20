defmodule Thumbtack.SingleImageUploadTest do
  alias Thumbtack.User

  use Thumbtack.TestCase

  defmodule UserPhoto do
    @behaviour Thumbtack.ImageUpload

    use Thumbtack.ImageUpload, foreign_key: :user_id

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "user_photos" do
      belongs_to :user, User
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

  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  describe "upload(owner, src_path)" do
    test "implements image upload workflow; accepts owner id", %{user: user} do
      %User{id: user_id} = user

      assert {:ok, %UserPhoto{user_id: ^user_id} = _image_upload,
              %{original: _original_url, thumb: _thumb_url} = _urls} =
               UserPhoto.upload(user_id, "test/fixtures/photo-small.jpg")
    end

    test "returns error if upload fails", %{user: user} do
      assert {:error, _message} =
               UserPhoto.upload(user, "test/fixtures/photo-unknown.jpg")
    end
  end

  describe "get_url(owner, args)" do
    test "returns an image url for a given style", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert "http://localhost:4000/uploads/#{user.id}/#{photo_id}-thumb.png" ==
               UserPhoto.get_url(user, style: :thumb)
    end

    test "default style if original", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert "http://localhost:4000/uploads/#{user.id}/#{photo_id}-original.png" ==
               UserPhoto.get_url(user)
    end

    test "returns nil if image not found", %{user: user} do
      assert is_nil(UserPhoto.get_url(user, %{style: :thumb}))
    end
  end

  describe "delete(module, owner)" do
    test "deletes image upload", %{user: user} do
      {:ok, %UserPhoto{id: photo_id}} = UserPhoto.create_image_upload(user)

      assert {:ok, %UserPhoto{id: ^photo_id}} = UserPhoto.delete(user)
    end

    test "returns error tuple if image not found", %{user: user} do
      assert {:error, :not_found} = UserPhoto.delete(user)
    end
  end
end
