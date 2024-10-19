defmodule Thumbtack.ImageUpload.SingleImageSchemaTest do
  alias Thumbtack.User

  use Thumbtack.TestCase

  defmodule UserPhoto do
    alias Thumbtack.User

    use Thumbtack.ImageUpload.Schema,
      foreign_key: :user_id

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "user_photos" do
      belongs_to :user, User
    end
  end

  describe "create_image_upload(owner_or_id)" do
    test "creates image upload record in repo" do
      user = insert(:user)
      assert {:ok, %UserPhoto{}} = UserPhoto.create_image_upload(user)
    end

    test "accepts owner id" do
      %{id: user_id} = insert(:user)
      assert {:ok, %UserPhoto{}} = UserPhoto.create_image_upload(user_id)
    end

    test "validates uniqueness of image upload per owner" do
      user = insert(:user)
      UserPhoto.create_image_upload(user)

      assert {:error, _changeset} = UserPhoto.create_image_upload(user)
    end
  end

  describe "get_image_upload(owner_or_id)" do
    test "returns image upload for a given owner" do
      user = insert(:user)

      {:ok, %UserPhoto{id: image_upload_id}} = UserPhoto.create_image_upload(user)

      assert %UserPhoto{
               id: ^image_upload_id
             } = UserPhoto.get_image_upload(user)
    end

    test "accepts owner id" do
      %User{id: user_id} = insert(:user)

      {:ok, %UserPhoto{id: image_upload_id}} = UserPhoto.create_image_upload(user_id)

      assert %UserPhoto{
               id: ^image_upload_id,
               user_id: ^user_id
             } = UserPhoto.get_image_upload(user_id)
    end

    test "returns nil if image upload does not exist for a given owner" do
      user = insert(:user)
      refute UserPhoto.get_image_upload(user)
    end
  end

  describe "get_or_create_image_upload(owner_or_id)" do
    test "returns existing image upload" do
      user = insert(:user)

      {:ok, %UserPhoto{id: image_upload_id}} = UserPhoto.create_image_upload(user)

      assert %UserPhoto{
               id: ^image_upload_id
             } = UserPhoto.get_or_create_image_upload(user)
    end

    test "creates new image upload, if one does not exist; accepts owner id" do
      %{id: user_id} = insert(:user)
      assert %UserPhoto{} = UserPhoto.get_or_create_image_upload(user_id)
    end
  end

  describe "delete_image_upload(struct)" do
    test "deletes image upload" do
      user = insert(:user)

      {:ok, %{id: image_upload_id} = image_upload} = UserPhoto.create_image_upload(user)

      assert {:ok, %UserPhoto{id: ^image_upload_id}} = UserPhoto.delete_image_upload(image_upload)

      refute UserPhoto.get_image_upload(user)
    end
  end
end
