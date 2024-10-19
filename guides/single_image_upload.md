# Single image upload

> This guide is a work in progress.

Assume you have `User` schema in your app:

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
  end
end
```


### Migration

```elixir
defmodule MyApp.Repo.Migrations.CreateUserPhotos do
  use Ecto.Migration

  def change do
    create table("user_photos", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
    end

    create unique_index(:user_photos, [:user_id])
  end
end
```


### Schemas

1. Add your file attachment schema module:

```elixir
defmodule MyApp.UserPhoto do
  @behaviour Thumbtack.ImageUpload

  # this line adds `use Ecto.Schema`
  use Thumbtack.ImageUpload, foreign_key: :user_id

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_photos" do
    belongs_to :user, MyApp.User
  end

  # you must implement this callback
  @impl true
  def get_path(user_id, photo_id, %{style: style} = _args) do
    "/accounts/users/#{user_id}/#{photo_id}-#{style}.jpg"
  end

  # you must implement this callback
  @impl true
  def styles do
    [
      original: [:square, {:resize, 256}],
      thumb: [{:thumbnail, size: 64, source: :original}]
    ]
  end
end
```

2. Add `has_one` association to the parent schema:

```elixir
defmodule MyApp.User do
  # ...
  schema "users" do
    # ...
    has_one :photo, MyApp.UserPhoto
  end
end

```


### Work with image uploads

When you add `use Thumbtack.ImageUpload` code to your `UserPhoto` module, the library 
adds these functions to it:

 * `upload(user, src_path)` - takes image from file located at `src_path` (usually temporary file), 
 processes image and uploads it to the storage. Also creates a record in the database.
 
 * `get_url(user, style: style)` - returns an image URL for a given `style`.
 Styles are defined in `styles()` callback you implement in your schema module
 
 * `delete(user)` - deletes the image associated with `user` from storage
 and the corresponding record from database.

 You can use those functions in your domain code:

```elixir
defmodule MyApp.Accounts do
  # ...

  def upload_user_photo(%User{} = user, src_path) do
    UserPhoto.upload(user, src_path)
  end

  def get_user_photo_url(user_or_id, style \\ :original) do
    UserPhoto.get_url(user_or_id, style: style)
  end

  def delete_user_photo(%User{} = user) do
    UserPhoto.delete(user)
  end
end
```

Here is how you can use `upload()` function with
[Phoenix LiveView uploads](https://hexdocs.pm/phoenix_live_view/uploads.html):

```elixir
def handle_event("save-photo", _params, socket) do
  user = socket.assigns.user

  urls = 
    consume_uploaded_entries(socket, :photo, fn %{path: tmp_path}, _entry ->
      {:ok, _user_photo, urls} = 
                  MyApp.Accounts.upload_user_photo(socket.assigns.user, tmp_path)
      {:ok, urls}
    end)

  %{original: original_url, thumb: thumb_url} = urls
  # ...

  {:noreply, socket}
end
```
