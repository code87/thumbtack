defmodule Thumbtack.Storage.Local do
  @moduledoc """
  Local file system storage provider implementation.

  ### Configuration:

      # config/dev.exs
      config :thumbtack, Thumbtack.Storage.Local,
        root_url: "http://localhost:4000/uploads",
        # MAKE SURE THIS PATH EXISTS
        storage_path: "/media/uploads"

      # MyAppWeb.Endpoint
      plug Plug.Static, at: "/uploads", from: "/media/uploads"

  """
  @behaviour Thumbtack.Storage

  @doc """
  Returns configured local storage root URL.

  Example:
      > root_url()
      "http://localhost:4000/uploads"

  """
  @impl true
  def root_url(), do: Thumbtack.config(__MODULE__)[:root_url]

  @doc """
  Returns configured local storage path.

  Example:
      > storage_path()
      "/media/uploads"

  """
  def storage_path, do: Thumbtack.config(__MODULE__)[:storage_path]

  @doc """
  Copies file from `src_path` to `dest_path` (relative to configured `:root_url`).
  Missing parent directories are created if needed.

  Returns `{:ok, url}` or error tuple.

  Examples:
      > put("/tmp/uploads/tempfile.jpg", "/photos/123/photo.jpg")
      {:ok, "http://localhost:4000/uploads/photos/123/photo.jpg"}

      > put("/tmp/uploads/unknown.jpg", "/photos/123/photo.jpg")
      {:error, :enoent}

  """
  @impl true
  def put(src_path, dest_path) do
    if File.exists?(src_path) do
      do_put(src_path, dest_path)
    else
      {:error, :enoent}
    end
  end

  defp do_put(src_path, dest_path) do
    storage_path = storage_path()

    dest_dir = Path.join(storage_path, Path.dirname(dest_path))
    :ok = File.mkdir_p(dest_dir)

    full_path = Path.join(storage_path, dest_path)

    case File.cp(src_path, full_path) do
      :ok ->
        {:ok, url_for_path(dest_path)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Deletes file at `path` (relative to configured `:root_url`).

  Returns `{:ok, url}` or error tuple.

  Examples:
      > delete("/photos/123/photo.jpg")
      {:ok, "http://localhost:4000/uploads/photos/123/photo.jpg"}

      > delete("/photos/123/unknown.jpg")
      {:error, :enoent}

  """
  @impl true
  def delete(path) do
    full_path = Path.join(storage_path(), path)

    case File.rm(full_path) do
      :ok ->
        {:ok, url_for_path(path)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp url_for_path(path), do: Path.join(root_url(), path)
end
