defmodule Thumbtack.Image do
  @moduledoc false

  alias Vix.Vips

  @supported_formats [:png, :jpg]
  @default_format :png
  @vips_save_opts "[Q=90,strip]"

  @type image_or_path :: Vips.Image.t() | String.t()

  @spec load_image(path :: String.t()) :: {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def load_image(path) when is_binary(path), do: Vips.Image.new_from_file(path)

  @spec save_image(image :: Vips.Image.t(), path :: String.t(), format :: atom()) ::
          :ok | {:error, term()}
  @doc false
  def save_image(image, path, format \\ @default_format)

  def save_image(image, path, format) when format in @supported_formats do
    Vips.Image.write_to_file(image, path <> @vips_save_opts)
  end

  def save_image(_, _, format),
    do: raise(ArgumentError, "Thumbtack.Image: unsupported image format #{format}")

  @spec format_supported?(format :: atom()) :: boolean()
  @doc false
  def format_supported?(format)
  def format_supported?(format) when format in @supported_formats, do: true
  def format_supported?(_format), do: false

  @spec format_extension(format :: atom()) :: String.t() | ArgumentError
  @doc false
  def format_extension(format)

  def format_extension(format) when format in @supported_formats do
    "." <> to_string(format)
  end

  def format_extension(format),
    do: raise(ArgumentError, "Thumbtack.Image: unsupported image format #{format}")

  @spec dimensions(image :: Vips.Image.t()) :: {width :: integer(), height :: integer()}
  @doc false
  def dimensions(%Vips.Image{} = image) do
    {Vips.Image.width(image), Vips.Image.height(image)}
  end

  @spec square(image_or_path :: image_or_path()) :: {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def square(image_or_path)

  def square(%Vips.Image{} = image) do
    width = Vips.Image.width(image)
    height = Vips.Image.height(image)

    if width != height do
      size = min(width, height)

      {left, top} =
        if width > height do
          {div(width - size, 2), 0}
        else
          {0, div(height - size, 2)}
        end

      Vips.Operation.extract_area(image, left, top, size, size)
    else
      {:ok, image}
    end
  end

  def square(path) when is_binary(path) do
    case load_image(path) do
      {:ok, %Vips.Image{} = image} ->
        square(image)

      {:error, term} ->
        {:error, term}
    end
  end

  @spec resize(image_or_path :: image_or_path(), size :: integer()) ::
          {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def resize(image_or_path, size)

  def resize(%Vips.Image{} = image, size) do
    {width, height} = {Vips.Image.width(image), Vips.Image.height(image)}
    {hscale, vscale} = {size / width, size / height}
    scale = min(hscale, vscale)

    if scale < 1.0 do
      Vips.Operation.resize(image, scale)
    else
      {:ok, image}
    end
  end

  def resize(path, size) when is_binary(path) do
    case load_image(path) do
      {:ok, %Vips.Image{} = image} ->
        resize(image, size)

      {:error, term} ->
        {:error, term}
    end
  end

  @spec thumbnail(image_or_path :: image_or_path(), size :: integer()) ::
          {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def thumbnail(path, size)

  def thumbnail(path, size) when is_binary(path) do
    Vips.Operation.thumbnail(path, size)
  end

  def thumbnail(%Vips.Image{} = _image, _size),
    do: raise(ArgumentError, "Thumbtack.Image: thumbnail only supports file path")
end
