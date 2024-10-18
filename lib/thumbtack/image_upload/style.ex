defmodule Thumbtack.ImageUpload.Style do
  @moduledoc false

  alias Thumbtack.ImageUpload.Uploader
  alias Thumbtack.ImageUpload.Transformation

  alias Vix.Vips

  @type t :: %__MODULE__{
          image: Vix.Vips.Image.t(),
          path: String.t()
        }

  @save_opts strip: true, Q: 80

  defstruct image: nil, path: nil

  @spec new(attrs :: keyword()) :: t()
  @doc false
  def new(attrs \\ []) do
    Map.merge(%__MODULE__{}, Enum.into(attrs, %{}))
  end

  @spec process(uploader :: Uploader.t(), transformations :: [Transformation.t()]) ::
          t() | {:error, term()}
  @doc false
  def process(uploader, transformations) do
    new()
    |> apply_transformations(transformations, uploader)
    |> save()
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
  def save(%__MODULE__{image: %Vips.Image{} = image} = style_state) do
    path =
      System.tmp_dir()
      |> Path.join(Ecto.UUID.generate() <> ".jpg")

    case Vips.Operation.jpegsave(image, path, @save_opts) do
      :ok ->
        %__MODULE__{style_state | path: path}

      {:error, term} ->
        {:error, term}
    end
  end

  # for piping
  def save({:error, term}), do: {:error, term}
end
