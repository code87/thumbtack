# Image transformations

> This guide is a work in progress.

 * `:square` - cuts central square from image, if image is rectangular
 * `:resize` - downscales a square image to a given size, if image is larger
 * `:thumbnail` - generates an image thumbnail from another style image


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


### Downscale square image

Usage: `{:resize, size}`

```elixir
def MyApp.UserPhoto do
  @size 256

  @impl true
  def styles do
    [
      original: [:square, {:resize, @size}]
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
