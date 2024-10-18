defmodule Thumbtack.ImageUpload do
  @moduledoc """
  This module adds image attachment capabilities to your Ecto schemas.

  > This page is a work in progress.

  ### Options

    * `:belongs_to` - a `{field, module}` tuple which defines a belongs-to association. Example: `{:user, MyApp.User}`
    * `:foreign_key` - parent id field. Example: `:user_id`
    * `:schema` - name of a schema to define. Example: `"user_photos"`
    * `:max_images` - *optional*. Maximum number of images that may be uploaded and attached to parent record
    (defined by `:belongs_to`). Must be an integer from `1` to `10_000`. Default: `1`.

  Example:
      defmodule MyApp.User do
        schema "users" do
          has_one :photo, MyApp.UserPhoto
        end
      end

      defmodule MyApp.UserPhoto do
        use Thumbtack.ImageUpload,
                belongs_to: {:user, MyApp.User},
                foreign_key: :user_id,
                schema: "user_photos"
      end

  **NOTE.** You still have to write repo migration yourself. Please refer to
  [Single image upload](guides/single_image_upload.md) or
  [Multiple image uploads](guides/multiple_image_uploads.md) guide depending on your use case.

  """

  alias Thumbtack.ImageUpload.Uploader

  #
  # Types
  #

  @type transformation_def :: atom() | {atom(), keyword()} | {atom(), term()}
  @type style_def :: {atom(), [transformation_def()]}

  @typep owner_or_id :: struct() | :id
  @typep upload_result ::
           {:ok, image_upload :: struct(), urls :: %{atom() => String.t()}} | {:error, term()}

  #
  # Callbacks
  #

  @doc """
  This callback should generate relative path for image upload files.

  Arguments:
    * `owner_id` - an id of image upload parent entity (e.g. `User`)
    * `image_upload_id` - a binary id of image upload entity (e.g. `UserPhoto`)
    * `opts` - a keyword list. The following options are supported:
      * `style` - a variation of an image. For example, `:original`, `thumb` etc.

  Example implementation:

      defmodule MyApp.UserPhoto do
        @behaviour Thumbtack.ImageUpload

        @impl true
        def get_path(user_id, photo_id, style: style) do
          "/accounts/users/\#{user_id}/\#{photo_id}-\#{style}.jpg"
        end
      end

      UserPhoto.get_path(124, "456-abc", style: :thumb)
      > "/accounts/users/123/456-abc-thumb.jpg"

  """
  @callback get_path(owner_id :: :id, image_upload_id :: :binary_id, args :: keyword()) ::
              String.t()

  @doc """
  This callback should return an information about supported image _styles_ along
  with a list of image transformations to be applied for each style during the upload process.

  You may give your image styles any names you like (e.g. `:thumb`, `:medium`, `:xlarge`).
  However each image must have `:original` style defined.

  For a list of supported image transformations see
  [Image transformations](guides/image_transformations.md) guide.

  Example implementation:

      defmodule UserPhoto do
        @behaviour Thumbtack.ImageUpload

        @impl true
        def styles do
          [
            original: [:square, {:resize, 256}],
            thumb: [{:thumbnail, size: 64, source: :original}]
          ]
        end
      end

  """
  @callback styles() :: [style_def()]

  #
  # Functions
  #

  @spec upload(
          module :: atom(),
          owner_or_id :: owner_or_id(),
          src_path :: String.t(),
          args :: keyword()
        ) ::
          upload_result()
  @doc false
  def upload(module, owner_or_id, src_path, args \\ []) do
    Thumbtack.repo().transaction(fn ->
      index = Keyword.get(args, :index, 0)

      Uploader.new(
        module: module,
        owner: owner_or_id,
        styles: module.styles(),
        src_path: src_path,
        index: index
      )
      |> Uploader.validate_args()
      |> Uploader.maybe_download_image()
      |> Uploader.validate_image()
      |> Uploader.process_styles()
      |> Uploader.get_or_create_image_upload()
      |> Uploader.put_to_storage()
      |> Uploader.verify()
    end)
    |> handle_result()
  end

  defp handle_result(result_or_error)

  defp handle_result({:ok, {:ok, image_upload, urls}}) do
    {:ok, image_upload, urls}
  end

  defp handle_result({:error, {:error, term}}) do
    {:error, term}
  end

  @spec get_url(module :: atom(), owner_or_id :: owner_or_id(), args :: keyword()) :: String.t()
  @doc false
  def get_url(module, owner_or_id, args \\ [])

  def get_url(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    get_url(module, owner_id, args)
  end

  def get_url(module, owner_id, args) do
    opts = fetch_options(args)

    case module.get_image_upload(owner_id, opts) do
      %{id: image_upload_id} ->
        Path.join(
          Thumbtack.storage().root_url(),
          module.get_path(owner_id, image_upload_id, opts)
        )

      nil ->
        nil
    end
  end

  @spec delete(module :: atom(), owner_or_id :: owner_or_id(), args :: keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @doc false
  def delete(module, owner_or_id, args \\ [])

  def delete(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    delete(module, owner_id, args)
  end

  def delete(module, owner_id, args) do
    case module.get_image_upload(owner_id, fetch_options(args)) do
      %{id: _id} = image_upload ->
        module.delete_image_upload(image_upload)

      nil ->
        {:error, :not_found}
    end
  end

  defp fetch_options(args) do
    [
      index: Keyword.get(args, :index, 0),
      style: Keyword.get(args, :style, :original)
    ]
  end

  #
  # Macros
  #

  defmacro __using__(opts) do
    quote do
      use Thumbtack.ImageUpload.Schema, unquote(opts)

      @spec upload(owner :: struct() | :id, src_path :: String.t(), args :: keyword()) ::
              {:ok, image_upload :: struct(), urls :: %{atom() => String.t()}} | {:error, term()}
      @doc """
      """
      def upload(owner, src_path, args \\ []) do
        Thumbtack.ImageUpload.upload(__MODULE__, owner, src_path)
      end

      @spec get_url(owner :: struct() | :id, args :: keyword()) :: String.t() | nil
      @doc """
      """
      def get_url(owner, args \\ [style: :original]) do
        Thumbtack.ImageUpload.get_url(__MODULE__, owner, args)
      end

      @spec delete(owner :: struct() | :id, args :: keyword()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}
      @doc """
      """
      def delete(owner, args \\ []) do
        Thumbtack.ImageUpload.delete(__MODULE__, owner, args)
      end
    end
  end
end
