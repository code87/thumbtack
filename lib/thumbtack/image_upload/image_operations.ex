defmodule Thumbtack.ImageUpload.ImageOperations do
  @moduledoc false
  alias Vix.Vips

  @spec square(image_or_path :: Vips.Image.t() | String.t()) ::
          {:ok, Vips.Image.t()} | {:error, term()}
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
      %Vips.Image{} = image ->
        square(image)

      {:error, term} ->
        {:error, term}
    end
  end

  @spec resize(image_or_path :: Vips.Image.t() | String.t(), size :: integer()) ::
          {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def resize(image_or_path, size)

  def resize(%Vips.Image{} = image, size) do
    scale = size / Vips.Image.width(image)

    if scale < 1.0 do
      Vips.Operation.resize(image, scale)
    else
      {:ok, image}
    end
  end

  def resize(path, size) when is_binary(path) do
    case load_image(path) do
      %Vips.Image{} = image ->
        resize(image, size)

      {:error, term} ->
        {:error, term}
    end
  end

  @spec thumbnail(path :: String.t(), size :: integer()) ::
          {:ok, Vips.Image.t()} | {:error, term()}
  @doc false
  def thumbnail(path, size) when is_binary(path) do
    Vips.Operation.thumbnail(path, size)
  end

  defp load_image(path) do
    case Vips.Image.new_from_file(path) do
      {:ok, %Vips.Image{} = image} ->
        image

      {:error, term} ->
        {:error, term}
    end
  end
end
