defmodule Thumbtack.ImageUpload.Uploader do
  @moduledoc false
  #
  # Image upload workflow implementation.
  #
  # ### Workflow
  #
  #   * Initialize state
  #   * Maybe download image (if source path is a URL)
  #   * Check if the file at source path exists, validate image file
  #   * For each `{style, transformations}` in `styles`
  #     - for each `{transformation, args}` in `transformations`
  #       - maybe load `image` (special case: `:thumbnail` transformation)
  #       - transform `image`
  #       - update state with `%{style => %{image: image}}`
  #     - save `image` to temporary file at `path`
  #     - update state with `%{style => %{path: path}}`
  #     - Return `{:ok, %{style => path}}`
  #   * Get/create image upload record from/in repo
  #   * For each style
  #     * put style image to storage
  #     * generate style image URL
  #   * Cleanup
  #   * Return image upload and style urls
  #

  alias Thumbtack.ImageUpload.Transformation
  alias Thumbtack.ImageUpload.Style

  @type t :: %__MODULE__{
          module: atom(),
          owner: struct() | :id,
          index: integer(),
          src_path: String.t(),
          styles: [{atom(), [Transformation.t()]}],
          state: %{atom() => Style.t()},
          image_upload: struct()
        }

  @type upload_result :: {:ok, image_upload :: struct()} | {:error, term()}

  defstruct module: nil,
            owner: nil,
            index: 0,
            foreign_key: nil,
            src_path: "",
            styles: [],
            state: %{},
            image_upload: nil

  @spec new(attrs :: keyword()) :: t()
  @doc false
  def new(attrs \\ []) do
    Map.merge(%__MODULE__{}, Enum.into(attrs, %{}))
  end

  #
  # TODO: validate module (with styles) and owner
  #
  @doc false
  def validate_args(%__MODULE__{index: index, module: module} = uploader) do
    if index >= 0 && index < module.max_images() do
      uploader
    else
      {:error, :index_out_of_bounds, uploader}
    end
  end

  @doc false
  def maybe_download_image(uploader_or_error)

  def maybe_download_image(%__MODULE__{src_path: "http" <> _rest_of_url} = uploader) do
    {:error, "Thumbtack.ImageUpload.Uploader: downloading images by URL is not yet implemented",
     uploader}
  end

  def maybe_download_image(%__MODULE__{src_path: src_path} = uploader) when is_binary(src_path) do
    uploader
  end

  def maybe_download_image({:error, term, uploader}), do: {:error, term, uploader}

  @doc false
  def validate_image(uploader_or_error)

  def validate_image(%__MODULE__{src_path: src_path} = uploader) do
    #
    # This must be efficient. Excerpt from Vix docs:
    #
    #   Loading is fast: only enough of the image is loaded to be able to fill out the header.
    #   Pixels will only be decompressed when they are needed.
    #
    case Vix.Vips.Image.new_from_file(src_path) do
      {:ok, %Vix.Vips.Image{} = _image} ->
        # TODO: use this image in first style processing, if possible
        uploader

      {:error, message} ->
        {:error, message, uploader}
    end
  end

  def validate_image({:error, term, uploader}), do: {:error, term, uploader}

  @doc false
  def process_styles(uploader_or_error)

  def process_styles(%__MODULE__{styles: styles} = uploader) do
    Enum.reduce_while(styles, uploader, fn {style, transformations}, uploader ->
      case Style.process(uploader, transformations) do
        style_state = %Style{} ->
          updated_uploader = %__MODULE__{
            uploader
            | state: Map.put(uploader.state, style, style_state)
          }

          {:cont, updated_uploader}

        {:error, term} ->
          {:halt, {:error, term, uploader}}
      end
    end)
  end

  def process_styles({:error, term, uploader}), do: {:error, term, uploader}

  @doc false
  def get_or_create_image_upload(uploader_or_error)

  def get_or_create_image_upload(%__MODULE__{} = uploader) do
    %{module: module, owner: owner, index: index} = uploader
    %__MODULE__{uploader | image_upload: module.get_or_create_image_upload(owner, %{index: index})}
  end

  def get_or_create_image_upload({:error, term, uploader}), do: {:error, term, uploader}

  @doc false
  def put_to_storage(uploader_or_error)

  def put_to_storage(%__MODULE__{} = uploader) do
    %{state: state, module: module, owner: owner, index: index, image_upload: image_upload} =
      uploader

    owner_id = fetch_owner_id(owner)
    %{id: image_upload_id} = image_upload

    styles = Map.keys(state)

    Enum.reduce_while(styles, uploader, fn style, uploader_acc ->
      style_state = Map.get(state, style)
      %{path: path} = style_state

      dest_path = module.get_path(owner_id, image_upload_id, %{index: index, style: style})

      case Thumbtack.storage().put(path, dest_path) do
        {:ok, url} ->
          {:cont,
           %__MODULE__{
             uploader_acc
             | state: Map.put(uploader_acc.state, style, Map.put(style_state, :url, url))
           }}

        _ ->
          {:halt, {:error, "Thumbtack.ImageUpload: upload failed", uploader}}
      end
    end)
  end

  def put_to_storage({:error, term, uploader}), do: {:error, term, uploader}

  defp fetch_owner_id(%{id: owner_id} = owner) when is_struct(owner), do: owner_id
  defp fetch_owner_id(owner_id), do: owner_id

  @doc false
  def verify(uploader_or_error)

  def verify(%__MODULE__{image_upload: image_upload, state: state}) do
    urls =
      state
      |> Enum.map(fn {style, %{:url => url}} -> {style, url} end)
      |> Enum.into(%{})

    {:ok, image_upload, urls}
  end

  def verify({:error, term, %__MODULE__{} = _uploader}) do
    if Thumbtack.repo().in_transaction?() do
      Thumbtack.repo().rollback({:error, term})
    else
      {:error, term}
    end
  end
end
