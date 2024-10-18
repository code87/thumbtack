defmodule Thumbtack.Storage do
  @moduledoc """
  This module defines callbacks to be implemented in storage providers.
  """

  @doc """
  This callback must return a configured root URL of a storage.

  Examples:
      > root_url()
      "http://localhost:4000/uploads"

      > root_url()
      "https://my-bucket.s3.amazonaws.com/"

  """
  @callback root_url() :: String.t()

  @doc """
  This callback must copy or upload a local file located at `src_path` to
  `dest_path` of the storage (relative to `root_url()`).

  Return values:
    * `{:ok, url}` where `url` is a URL to a file uploaded
    * `{:error, reason}`

  Examples:
      > put("/tmp/my-file.txt", "/users/123/info.txt")
      {:ok, "http://localhost:4000/uploads/users/123/info.txt"}

      > put("/tmp/my-file.txt", "/users/123/info.txt")
      {:ok, "https://my-bucket.s3.amazonaws.com/uploads/users/123/info.txt"}

  """
  @callback put(src_path :: String.t(), dest_path :: String.t()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  This callback should delete a file located at `path` in the storage (relative to `root_url()`).

  Returns:
    * `{:ok, url}` where `url` is a URL of a deleted file
    * `{:error, reason}`

  Examples:
      > delete("/users/123/info.txt")
      {:ok, "https://my-bucket.s3.amazonaws.com/uploads/users/123/info.txt"}

      > delete("/users/123/info.txt")
      {:error, :not_found}

  """
  @callback delete(path :: String.t()) :: {:ok, String.t()} | {:error, term()}
end
