defmodule Thumbtack.ImageUpload.Schema do
  @moduledoc false

  @max_images_limit 10_000

  @doc false
  def create(module, owner_or_id, args)

  def create(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    create(module, owner_id, args)
  end

  def create(module, owner_id, args) do
    struct(module)
    |> module.image_upload_changeset(owner_id, args_to_map(args))
    |> Thumbtack.repo().insert()
  end

  @doc false
  def get(module, owner_or_id, args)

  def get(module, %{id: owner_id} = owner, args) when is_struct(owner) do
    get(module, owner_id, args)
  end

  def get(module, owner_id, args) do
    Thumbtack.repo().get_by(module, module.query_params(owner_id, args_to_map(args)))
  end

  # in case of single upload index will be nil, so nothing to shift
  def shift_indexes(_module, _owner_id, nil, _callback), do: :ok

  def shift_indexes(module, owner_id, index, callback) do
    require Ecto.Query
    import Ecto.Query

    conditions =
      dynamic(
        [module],
        field(module, ^module.foreign_key()) == ^owner_id and module.index_number > ^index
      )

    order_by = [asc: dynamic([module], module.index_number)]

    from(module, where: ^conditions, order_by: ^order_by)
    |> Thumbtack.repo().all()
    |> Enum.each(&shift_image_upload(module, &1, callback))
  end

  def update_last_updated_at(module, image_upload) do
    image_upload
    |> module.update_last_updated_at()
    |> Thumbtack.repo().update!()
  end

  @doc false
  def delete(struct) do
    Thumbtack.repo().delete(struct)
  end

  defp shift_image_upload(module, image_upload, callback) do
    module.image_shift_changeset(image_upload, image_upload.index_number - 1)
    |> Thumbtack.repo().update!()

    callback.(image_upload.index_number)
  end

  defp args_to_map(args), do: Enum.into(args, %{})

  defmacro __using__(opts) do
    foreign_key = Keyword.fetch!(opts, :foreign_key)
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

      @spec max_images() :: integer()
      @doc """
      Returns a maximum number of image uploads that can be associated with a parent model.
      """
      def max_images, do: unquote(max_images)

      @spec foreign_key() :: atom()
      @doc """
      Returns a foreign key name that is used to associate image uploads with a parent model.
      """
      def foreign_key, do: unquote(foreign_key)

      @spec create_image_upload(owner_or_id :: struct | :id, args :: map() | keyword()) ::
              {:ok, struct} | {:error, Ecto.Changeset.t()}
      @doc """
      Creates a new image upload record in the repo.
      """
      def create_image_upload(owner_or_id, args \\ %{}) do
        Thumbtack.ImageUpload.Schema.create(__MODULE__, owner_or_id, args)
      end

      @spec get_image_upload(owner_or_id :: struct() | :id, args :: map() | keyword()) ::
              struct() | nil
      @doc """
      Fetches an image upload from the repo by a given `owner_or_id`.

      Returns `nil` if image upload not found.
      """
      def get_image_upload(owner_or_id, args \\ %{}) do
        Thumbtack.ImageUpload.Schema.get(__MODULE__, owner_or_id, args)
      end

      @spec get_or_create_image_upload(owner_or_id :: struct() | :id, args :: map() | keyword()) ::
              struct() | {:error, Ecto.Changeset.t()}
      @doc """
      Fetches existing or creates new image upload for a given `owner_or_id`.
      """
      def get_or_create_image_upload(owner_or_id, args \\ %{}) do
        case get_image_upload(owner_or_id, args) do
          %{id: _image_upload_id} = image_upload ->
            image_upload

          nil ->
            {:ok, image_upload} = create_image_upload(owner_or_id, args)
            image_upload
        end
      end

      @spec delete_image_upload(image_upload :: struct()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}
      @doc """
      Deletes image upload from the repo.

      Returns `{:ok, image_upload}` or `{:error, %Ecto.Changeset{}}`.
      """
      def delete_image_upload(image_upload) when is_struct(image_upload, __MODULE__) do
        Thumbtack.ImageUpload.Schema.delete(image_upload)
      end

      @spec image_upload_changeset(struct :: struct(), owner_id :: :id, args :: map()) ::
              Ecto.Changeset.t()

      @doc false
      def image_upload_changeset(struct, owner_id, args \\ %{}) do
        struct
        |> put_changes(owner_id, args)
        |> put_change(:last_updated_at, Thumbtack.Utils.timestamp())
        |> validate_photo_uniqueness()
        |> maybe_validate_index_number()
      end

      @spec update_last_updated_at(struct :: struct()) :: Ecto.Changeset.t()
      def update_last_updated_at(struct) do
        struct
        |> change()
        |> put_change(:last_updated_at, Thumbtack.Utils.timestamp())
      end

      def image_shift_changeset(struct, new_index) do
        struct
        |> change()
        |> put_change(:index_number, new_index)
        |> put_change(:last_updated_at, Thumbtack.Utils.timestamp())
      end

      defp put_changes(changeset, owner_id, args) do
        changes =
          if unquote(max_images) > 1 do
            index = Map.get(args, :index, 0)
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
          |> validate_number(:index_number,
            greater_than_or_equal_to: 0,
            less_than: unquote(max_images)
          )
        else
          changeset
        end
      end

      @spec query_params(owner_id :: :id, args :: map()) :: map()
      @doc false
      def query_params(owner_id, args \\ %{}) do
        if unquote(max_images) > 1 do
          index = Map.get(args, :index, 0)
          %{unquote(foreign_key) => owner_id, :index_number => index}
        else
          %{unquote(foreign_key) => owner_id}
        end
      end
    end
  end
end
