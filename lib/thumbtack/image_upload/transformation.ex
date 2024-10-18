defmodule Thumbtack.ImageUpload.Transformation do
  @moduledoc false

  alias Thumbtack.ImageUpload.ImageOperations
  alias Thumbtack.ImageUpload.Style
  alias Thumbtack.ImageUpload.Uploader

  alias Vix.Vips

  @type t :: atom() | {atom(), keyword()} | {atom(), term()}

  @spec process(
          style_state :: Style.t(),
          transformation :: t(),
          uploader :: Uploader.t()
        ) :: Style.t() | {:error, term()}
  @doc false
  def process(style_state, transformation, uploader)

  def process(style_state, :square, uploader) do
    do_process(style_state, uploader, fn image_or_path ->
      ImageOperations.square(image_or_path)
    end)
  end

  def process(style_state, {:resize, size}, uploader) do
    do_process(style_state, uploader, fn image_or_path ->
      ImageOperations.resize(image_or_path, size)
    end)
  end

  # special case
  def process(style_state, {:thumbnail, size: size, source: source}, uploader) do
    with %Style{path: path} <- Map.get(uploader.state, source),
         true <- is_binary(path),
         {:ok, image} <- ImageOperations.thumbnail(path, size) do
      %Style{style_state | image: image}
    else
      _ ->
        {:error, :enoent}
    end
  end

  defp do_process(
         %Style{image: image} = style_state,
         %Uploader{src_path: src_path},
         transform_fun
       ) do
    image_or_path =
      if is_nil(image) do
        src_path
      else
        image
      end

    case transform_fun.(image_or_path) do
      {:ok, %Vips.Image{} = image} ->
        %Style{style_state | image: image}

      error ->
        error
    end
  end
end
