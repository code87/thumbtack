defmodule Thumbtack.ImageUpload do
  @moduledoc """
  This module adds image attachment capabilities to your Ecto schemas.

  > This page is a work in progress.

  ### Options

    * `:foreign_key` - parent id field. Example: `:user_id`

    * `:format` - *optional*. Image output file format. One of: `[:jpg, :png]`. Default: `:png`.

    * `:max_images` - *optional*. Maximum number of images that may be uploaded and attached to the parent record
    which image upload belongs to. Must be an integer from `1` to `10_000`. Default: `1`.

  Example 1:
      defmodule MyApp.UserPhoto do
        use Thumbtack.ImageUpload, foreign_key: :user_id

        @primary_key {:id, :binary_id, autogenerate: true}
        schema "user_photos" do
          belongs_to :user, MyApp.User
        end
      end

  Example 2:
      defmodule MyApp.AlbumPhoto do
        use Thumbtack.ImageUpload,
          foreign_key: :album_id,
          format: :jpg,
          max_images: 3

        @primary_key {:id, :binary_id, autogenerate: true}
        schema "album_photos" do
          belongs_to :album, MyApp.Album
          field :index_number, :integer, default: 0
        end
      end

  **NOTE.** You still have to write repo migration yourself.

  Please refer to [Single image upload](guides/single_image_upload.md) or
  [Multiple image uploads](guides/multiple_image_uploads.md) guide depending on your use case.

  """

  alias Thumbtack.ImageUpload.Uploader

  #
  # Types
  #

  @type transformation_def :: atom() | {atom(), keyword()} | {atom(), term()}
  @type style_def :: {atom(), [transformation_def()]}

  @typep owner_or_id :: struct() | :id
  @typep map_or_keyword :: map() | keyword()
  @typep upload_result ::
           {:ok, image_upload :: struct(), urls :: %{atom() => String.t()}} | {:error, term()}

  #
  # Callbacks
  #

  @doc """
  This callback should generate relative path for image upload files (*without file extension*).

  Arguments:
    * `owner_id` - an `:id` of image upload parent entity (e.g. `User`)
    * `image_upload_id` - a `:binary_id` of image upload entity (e.g. `UserPhoto`)
    * `args` - a map. The following keys are supported:
      * `:style` - a variation of an image. For example, `:original`, `:thumb` etc
      * `:index` - an index number in a collection of parent image uploads.

  Example 1:
      defmodule MyApp.UserPhoto do
        @behaviour Thumbtack.ImageUpload

        @impl true
        def path_prefix(user_id, photo_id, %{style: style}) do
          "/accounts/users/\#{user_id}/\#{photo_id}-\#{style}"
        end
      end

      UserPhoto.path_prefix(124, "456-abc", %{style: :thumb})
      > "/accounts/users/123/456-abc-thumb"

  Example 2:
      defmodule AlbumPhoto do
        @behaviour Thumbtack.ImageUpload

        @impl true
        def path_prefix(album_id, photo_id, %{index: index, style: style}) do
          "/albums/\#{album_id}/photos/\#{index}/\#{photo_id}-\#{style}"
        end
      end

      AlbumPhoto.path_prefix(124, "456-abc", %{index: 1, style: :md})
      > "/albums/124/photos/1/456-abc-md"

  """
  @callback path_prefix(owner_id :: :id, image_upload_id :: :binary_id, args :: map()) ::
              String.t()

  @doc """
  This callback should return an information about supported image styles along
  with a list of image transformations to be applied for each style during the upload process.

  You may give your image styles any names you like (e.g. `:thumb`, `:medium`, `:xlarge`).
  However, each image must have `:original` style defined.

  For the list of supported image transformations see
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
          args :: map_or_keyword()
        ) ::
          upload_result()
  @doc false
  def upload(module, owner_or_id, src_path, args) do
    index = Enum.into(args, %{}) |> Map.get(:index, 0)

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
  end

  @spec get_url(module :: atom(), owner_or_id :: owner_or_id(), args :: map_or_keyword()) ::
          String.t()
  @doc false
  def get_url(module, owner_or_id, args) do
    if path = get_path(module, owner_or_id, args) do
      Path.join(Thumbtack.storage().root_url(), path)
    else
      nil
    end
  end

  @spec get_path(
          module :: atom(),
          owner_or_id :: owner_or_id(),
          args :: map_or_keyword()
        ) :: String.t() | nil
  @doc false
  def get_path(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    get_path(module, owner_id, args)
  end

  def get_path(module, owner_id, args) do
    case module.get_image_upload(owner_id, args) do
      %{id: image_upload_id} ->
        get_path(module, owner_id, image_upload_id, args)

      nil ->
        nil
    end
  end

  @spec get_path(
          module :: atom(),
          owner_id :: :id,
          image_upload_id :: :binary_id,
          args :: map_or_keyword()
        ) :: String.t() | nil
  @doc false
  def get_path(module, owner_id, image_upload_id, args) do
    opts = fetch_options(args)

    extension =
      module.image_upload_format()
      |> Thumbtack.Image.format_extension()

    module.path_prefix(owner_id, image_upload_id, opts) <> extension
  end

  @spec delete(module :: atom(), owner_or_id :: owner_or_id(), args :: map_or_keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @doc false
  def delete(module, owner_or_id, args)

  def delete(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    delete(module, owner_id, args)
  end

  def delete(module, owner_id, args) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:image_upload, fn _repo, _changes ->
      case module.get_image_upload(owner_id, fetch_options(args)) do
        %{id: _id} = image_upload ->
          {:ok, image_upload}

        nil ->
          {:error, :not_found}
      end
    end)
    |> Ecto.Multi.run(:delete, fn _repo, %{image_upload: image_upload} ->
      module.delete_image_upload(image_upload)
    end)
    |> Ecto.Multi.run(:delete_folder, fn _repo, %{delete: image_upload} ->
      get_dir_name(module, owner_id, image_upload.id, args)
      |> Thumbtack.storage().delete_folder()
      |> case do
        :ok -> {:ok, image_upload}
        error -> {:error, error}
      end
    end)
    |> Ecto.Multi.run(:shift_indexes, fn _repo, %{delete: image_upload} ->
      Thumbtack.ImageUpload.Schema.shift_indexes(
        module,
        owner_id,
        Map.get(image_upload, :index_number, nil),
        fn updated_image_index ->
          original_dir_name =
            get_dir_name(module, owner_id, image_upload.id, %{index: updated_image_index})

          new_dir_name =
            get_dir_name(module, owner_id, image_upload.id, %{index: updated_image_index - 1})

          Thumbtack.storage().rename_folder(original_dir_name, new_dir_name)
        end
      )

      {:ok, image_upload}
    end)
    |> Thumbtack.Repo.transaction()
    |> case do
      {:ok, %{delete: image_upload}} -> {:ok, image_upload}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp get_dir_name(module, owner_id, image_upload_id, args) do
    module.path_prefix(owner_id, image_upload_id, fetch_options(args))
    |> Path.dirname()
  end

  defp fetch_options(args) do
    args_map = Enum.into(args, %{})

    %{
      index: Map.get(args_map, :index, 0),
      style: Map.get(args_map, :style, :original)
    }
  end

  #
  # Macros
  #

  defmacro __using__(opts) do
    format = Keyword.get(opts, :format, :png)

    if format not in [:jpg, :png] do
      raise ArgumentError, "Thumbtack: unsupported image format #{format}"
    end

    quote do
      use Thumbtack.ImageUpload.Schema, unquote(opts)

      @spec upload(owner :: struct() | :id, src_path :: String.t(), args :: map() | keyword()) ::
              {:ok, image_upload :: struct(), urls :: %{atom() => String.t()}} | {:error, term()}
      @doc """
      """
      def upload(owner, src_path, args \\ %{}) do
        Thumbtack.ImageUpload.upload(__MODULE__, owner, src_path, args)
      end

      @spec get_url(owner :: struct() | :id, args :: map() | keyword()) :: String.t() | nil
      @doc """
      """
      def get_url(owner, args \\ %{}) do
        Thumbtack.ImageUpload.get_url(__MODULE__, owner, args)
      end

      @spec delete(owner :: struct() | :id, args :: map() | keyword()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}
      @doc """
      """
      def delete(owner, args \\ %{}) do
        Thumbtack.ImageUpload.delete(__MODULE__, owner, args)
      end

      def image_upload_format, do: unquote(format)
    end
  end
end
