defmodule Thumbtack.ImageUpload.Style do
  @moduledoc false

  alias Thumbtack.Image
  alias Thumbtack.ImageUpload.Transformation
  alias Thumbtack.ImageUpload.Uploader

  alias Vix.Vips

  @type t :: %__MODULE__{
          image: Vix.Vips.Image.t(),
          path: String.t()
        }

  defstruct image: nil, path: nil

  @spec new(attrs :: keyword()) :: t()
  @doc false
  def new(attrs \\ []) do
    Map.merge(%__MODULE__{}, Enum.into(attrs, %{}))
  end

  @spec process(uploader :: Uploader.t(), transformations :: [Transformation.t()]) ::
          t() | {:error, term()}
  @doc false
  def process(%Uploader{module: module} = uploader, transformations) do
    new()
    |> apply_transformations(transformations, uploader)
    |> save(module.image_upload_format())
  end

  @doc false
  def apply_transformations(style_state, transformations, uploader) do
    Enum.reduce_while(transformations, style_state, fn transformation, style_state ->
      case Transformation.process(style_state, transformation, uploader) do
        updated_state = %__MODULE__{} ->
          {:cont, updated_state}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  @doc false
  def save(%__MODULE__{image: %Vips.Image{} = image} = style_state, format)
      when is_atom(format) do
    image_path =
      Image.format_extension(format)
      |> Thumbtack.Utils.generate_tempfile_path()

    case Image.save_image(image, image_path, format) do
      :ok ->
        %__MODULE__{style_state | path: image_path}

      {:error, term} ->
        {:error, term}
    end
  end

  # for piping
  def save({:error, term}, _format), do: {:error, term}
end
