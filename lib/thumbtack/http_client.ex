defmodule Thumbtack.HttpClient do
  @moduledoc false

  @httpc Application.compile_env(:thumbtack, :httpc, Thumbtack.HttpClient.Httpc)

  # download file at url and save to system temporary directory
  @spec download(url :: String.t()) :: {:ok, String.t()} | {:error, term()}
  def download("http" <> _rest = url) do
    path_to_file = Thumbtack.Utils.generate_tempfile_path()

    case @httpc.get(url, stream: to_charlist(path_to_file)) do
      :ok ->
        {:ok, path_to_file}

      %{status: code} = _response ->
        {:error, code}

      {:error, error} ->
        {:error, error}
    end
  end
end
