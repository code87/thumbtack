# Image transformations

> This guide is a work in progress.

 * `:square` - cuts central square from image, if image is rectangular
 * `{:resize, size}` - resizes image so that larger side (width or height) becomes `size`
 * `{:thumbnail, size: size, source: style}` - generates an image thumbnail from another style image


### Cut central square

Usage: `:square`

```elixir
def MyApp.UserPhoto do
  @impl true
  def styles do
    [
      original: [:square]
    ]
  end
end
```


### Resize image

Usage: `{:resize, size}`

This transformation does nothing, if larger side (width or height) of a given image is smaller than `size`.

```elixir
def MyApp.UserPhoto do
  @size 256

  @impl true
  def styles do
    [
      original: [:square]
      small: [:square, {:resize, @size}]
    ]
  end
end
```


### Thumbnail

Usage: `{:thumbnail, size: size, source: another_style}`

```elixir
def MyApp.UserPhoto do
  @size 256
  @thumb 64

  @impl true
  def styles do
    [
      original: [:square, {:resize, @size}],
      thumb: [{:thumbnail, size: @thumb, source: :original}]
    ]
  end
end
```
