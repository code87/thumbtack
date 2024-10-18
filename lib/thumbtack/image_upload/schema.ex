defmodule Thumbtack.ImageUpload.Schema do
  @moduledoc false

  @max_images_limit 10_000

  @doc false
  def create(module, owner_or_id, opts \\ [])

  def create(module, %{id: owner_id} = owner, opts) when is_struct(owner) do
    create(module, owner_id, opts)
  end

  def create(module, owner_id, opts) do
    struct(module)
    |> module.changeset(owner_id, opts)
    |> Thumbtack.repo().insert()
  end

  @doc false
  def get(module, owner_or_id, opts \\ [])

  def get(module, %{id: owner_id} = owner, opts) when is_struct(owner) do
    get(module, owner_id, opts)
  end

  def get(module, owner_id, opts) do
    Thumbtack.repo().get_by(module, module.query_params(owner_id, opts))
  end

  @doc false
  def delete(struct) do
    Thumbtack.repo().delete(struct)
  end

  defmacro __using__(opts) do
    {field, module} = Keyword.fetch!(opts, :belongs_to)
    foreign_key = Keyword.fetch!(opts, :foreign_key)
    schema_name = Keyword.fetch!(opts, :schema)
    max_images = Keyword.get(opts, :max_images, 1)

    if max_images < 1 do
      raise ArgumentError, "use Thumbtack.ImageUpload: max_images should be >= 1"
    end

    if max_images > @max_images_limit do
      raise ArgumentError, "use Thumbtack.ImageUpload: max_images should be >= 1"
    end

    quote do
      import Ecto.Changeset

      use Ecto.Schema

      @primary_key {:id, :binary_id, autogenerate: true}

      schema unquote(schema_name) do
        belongs_to unquote(field), unquote(module)

        if unquote(max_images) > 1 do
          field :index_number, :integer, default: 0
        end
      end

      @spec max_images() :: integer()
      @doc """
      Returns a maximum number of image uploads that can be associated with a parent model.
      """
      def max_images, do: unquote(max_images)

      @spec create_image_upload(owner_or_id :: struct | :id, opts :: keyword()) ::
              {:ok, struct} | {:error, Ecto.Changeset.t()}
      @doc """
      Creates a new image upload record in the repo.
      """
      def create_image_upload(owner_or_id, opts \\ []) do
        Thumbtack.ImageUpload.Schema.create(__MODULE__, owner_or_id, opts)
      end

      @spec get_image_upload(owner_or_id :: struct() | :id, opts :: keyword()) :: struct() | nil
      @doc """
      Fetches an image upload from the repo by a given `owner_or_id`.

      Returns `nil` if image upload not found.
      """
      def get_image_upload(owner_or_id, opts \\ []) do
        Thumbtack.ImageUpload.Schema.get(__MODULE__, owner_or_id, opts)
      end

      @spec get_or_create_image_upload(owner_or_id :: struct() | :id, opts :: keyword()) ::
              struct() | {:error, Ecto.Changeset.t()}
      @doc """
      Fetches existing or creates new image upload for a given `owner_or_id`.
      """
      def get_or_create_image_upload(owner_or_id, opts \\ []) do
        case get_image_upload(owner_or_id, opts) do
          %__MODULE__{id: _image_upload_id} = image_upload ->
            image_upload

          nil ->
            {:ok, %__MODULE__{} = image_upload} = create_image_upload(owner_or_id, opts)
            image_upload
        end
      end

      @spec delete_image_upload(image_upload :: struct()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}
      @doc """
      Deletes image upload from the repo.

      Returns `{:ok, image_upload}` or `{:error, %Ecto.Changeset{}}`.
      """
      def delete_image_upload(%__MODULE__{} = image_upload) do
        Thumbtack.ImageUpload.Schema.delete(image_upload)
      end

      @spec changeset(struct :: struct(), owner_id :: :id, opts :: keyword()) :: Ecto.Changeset.t()
      @doc false
      def changeset(struct, owner_id, opts \\ []) do
        struct
        |> put_changes(owner_id, opts)
        |> validate_photo_uniqueness()
        |> maybe_validate_index_number()
      end

      defp put_changes(changeset, owner_id, opts) do
        changes =
          if unquote(max_images) > 1 do
            index = Keyword.get(opts, :index, 0)
            %{unquote(foreign_key) => owner_id, :index_number => index}
          else
            %{unquote(foreign_key) => owner_id}
          end

        change(changeset, changes)
      end

      defp validate_photo_uniqueness(changeset) do
        if unquote(max_images) > 1 do
          unique_constraint(changeset, [unquote(foreign_key), :index_number])
        else
          unique_constraint(changeset, [unquote(foreign_key)])
        end
      end

      defp maybe_validate_index_number(changeset) do
        if unquote(max_images) > 1 do
          changeset
          |> validate_number(:index_number, greater_than_or_equal_to: 0, less_than: unquote(max_images))
        else
          changeset
        end
      end

      @spec query_params(owner_id :: :id, opts :: keyword()) :: map()
      @doc false
      def query_params(owner_id, opts \\ []) do
        if unquote(max_images) > 1 do
          index = Keyword.get(opts, :index, 0)
          %{unquote(foreign_key) => owner_id, :index_number => index}
        else
          %{unquote(foreign_key) => owner_id}
        end
      end
    end
  end
end
