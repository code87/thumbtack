# Thumbtack

`Thumbtack` is a file upload library for Elixir that adds attachment capabilities to Ecto schemas.

It supports multiple _styles_ for image uploads (e.g. `:original`, `:medium`, `:small` etc). 
Simple image transformations such as crop `:square`, `:resize` and `:thumbnail` are supported.

`Thumbtack` allows to specify output image file format (currently PNG or JPEG).

Library supports storage providers:
 * `Thumbtack.Storage.Local`
 * `Thumbtack.Storage.S3` (not released yet)

> **WARNING!** This project is a work in progress. Breaking changes may occur.

## Installation

In your `mix.exs`:

```elixir
defp deps do
  [
    # from github
    {:thumbtack, github: "code87/thumbtack", ref: "v0.0.2"},
  ]
end
```


## Usage example

For detailed information please check the `Thumbtack.ImageUpload` module docs.

### General configuration

```elixir
config :thumbtack,
  repo: MyApp.Repo,
  storage: Thumbtack.Storage.Local
```

### Storage configuration

If you choose to use local storage provider, add the following to your config:

```elixir
config :thumbtack, Thumbtack.Storage.Local,
  root_url: "http://localhost:4000/uploads",
  storage_path: "/media/uploads"
```

...and the following to your `endpoint.ex`:

```elixir
plug Plug.Static,
  at: "/uploads",
  from: "/media/uploads"
```

### Working with image uploads

Depending on your use case, please check one of the corresponding guides:
  * [Single image upload](guides/single_image_upload.md)
  * [Multiple image uploads](guides/multiple_image_uploads.md)

And once again, for detailed information please check the `Thumbtack.ImageUpload` module docs.

Enjoy!


## Copyright and License

Copyright (c) 2024, Code 87.

Source code is licensed under the [MIT License](LICENSE.md).
