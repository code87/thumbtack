# Multiple image uploads

> This guide is a work in progress.

Assume you have `Album` schema in your app:

```elixir
defmodule MyApp.Album do
  use Ecto.Schema

  schema "albums" do
    field :title, :string
  end
end
```


### Migration

```elixir
defmodule MyApp.Repo.Migrations.CreateAlbumPhotos do
  use Ecto.Migration

  def change do
    create table("album_photos", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :album_id, references(:albums), null: false
      add :index_number, :integer, null: false, default: 0
      add :last_updated_at, :utc_datetime, default: fragment("now()"), null: false
    end

    create unique_index(:album_photos, [:album_id, :index_number])
  end
end
```


### Schemas

1. Add your file attachment schema module:

```elixir
defmodule MyApp.AlbumPhoto do
  @behaviour Thumbtack.ImageUpload

  # this line adds `use Ecto.Schema`
  use Thumbtack.ImageUpload,
    foreign_key: :album_id,
    max_images: 3

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "album_photos" do
    belongs_to :album, MyApp.Album
    field :index_number, :integer, default: 0
    field :last_updated_at, :utc_datetime
  end

  # you must implement this callback
  @impl true
  def path_prefix(album_id, photo_id, %{index: index, style: style} = _args) do
    "/albums/#{album_id}/#{index}/#{photo_id}-#{style}"
  end

  # you must implement this callback
  @impl true
  def styles do
    [
      original: [:square],
      md: [:square, {:resize, 512}],
      sm: [:square, {:resize, 256}]
    ]
  end
end
```

2. Add `has_many` association to the parent schema:


```elixir
defmodule MyApp.Album do
  use Ecto.Schema

  schema "albums" do
    # ...
    has_many :photos, MyApp.AlbumPhoto
  end
end

```


### Work with image uploads

When you add `use Thumbtack.ImageUpload` code to your `AlbumPhoto` module, the library 
adds these functions to it:

 * `max_images()` - returns configured `:max_images` value (see schema definition above)

 * `upload(album, src_path, index: index)` - takes image from file located at `src_path`
 (usually temporary file), processes source image and uploads it to the storage. It assigns
 `:index` to the image and creates a database record

 * `get_url(album, index: index, style: style)` - returns an image URL for a given `style` and `index`
   * styles are defined in `styles()` callback you implement in your schema module
   * `index` is an integer in the range of `0..AlbumPhoto.max_images() - 1`

 * `delete(album, index: index)` - deletes image associated with given `album` and `index` from database and storage. If `index < AlbumPhoto.max_images() - 1`, it shifts all images with indexes greater than `index` to the left if any.

 You can use those functions in your domain code:

```elixir
defmodule MyApp.Albums do
  # ...

  def upload_album_photo(%Album{} = album, src_path, index) do
    AlbumPhoto.upload(album, src_path, index: index)
  end

  def get_album_photo_url(album_or_id, index, style \\ :original) do
    AlbumPhoto.get_url(album_or_id, index: index, style: style)
  end

  def delete_album_photo(%Album{} = album, index) do
    AlbumPhoto.delete(album, index: index)
  end
end
```

Here is how you can use `upload()` function with
[Phoenix LiveView uploads](https://hexdocs.pm/phoenix_live_view/uploads.html):

```elixir
def handle_event("save-photo", %{"index" => index} = _params, socket) do
  user = socket.assigns.user

  urls = 
    consume_uploaded_entries(socket, :photo, fn %{path: tmp_path}, _entry ->
      {:ok, _user_photo, urls} = 
                  MyApp.Accounts.upload_user_photo(socket.assigns.user, tmp_path, index)
      {:ok, urls}
    end)

  %{original: original_url, md: md_url, sm: sm_url} = urls
  # ...

  {:noreply, socket}
end
```
