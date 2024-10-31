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
  def root_url, do: Thumbtack.config(__MODULE__)[:root_url]

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

  @doc """
  Deletes folder at `path` (relative to configured `:root_url`) if folder is given or takes the file path and deletes the folder where the file is located.

  Returns `:ok` or error tuple.

  Examples:
      > delete_folder("/photos/123/photo.jpg") # deletes /photos/123 and its contents
      :ok

      > delete_folder("/photos/123") # deletes /photos/123 and its contents
      :ok

      > delete_folder("/photos/unknown/") # folder does not exist
      {:error, :enoent}
  """
  @impl true
  def delete_folder(nil), do: {:error, :enoent}

  def delete_folder(path) do
    validate_folder_exists(path)
    |> maybe_extract_folder()
    |> do_delete_folder()
  end

  @impl true
  def rename_folder(old_path, new_path) do
    # TODO: Implement this
    old_full_path = Path.join(storage_path(), old_path)
    new_full_path = Path.join(storage_path(), new_path)

    # case File.rename(old_full_path, new_full_path) do
    #  :ok ->
    #    {:ok, url_for_path(new_path)}

    #  {:error, reason} ->
    #    {:error, reason}
    # end
  end

  defp validate_folder_exists(path) do
    full_path = Path.join(storage_path(), path)

    if full_path != storage_path() && File.exists?(full_path) do
      {:ok, full_path}
    else
      {:error, :enoent}
    end
  end

  defp maybe_extract_folder({:error, reason}), do: {:error, reason}

  defp maybe_extract_folder({:ok, path}) do
    folder_path =
      if File.dir?(path) do
        path
      else
        Path.dirname(path)
      end

    {:ok, folder_path}
  end

  defp do_delete_folder({:error, reason}), do: {:error, reason}

  defp do_delete_folder({:ok, folder_path}) do
    IO.inspect(folder_path)

    case File.rm_rf(folder_path) do
      {:ok, _} ->
        :ok

      {:error, reason, _} ->
        {:error, reason}
    end
  end

  defp url_for_path(path), do: Path.join(root_url(), path)
end
