defmodule Thumbtack.FakeHttpc do
  @moduledoc false

  @fixtures_path "test/fixtures"

  @spec get(url :: String.t(), opts :: keyword()) :: :ok | map() | {:error, term()}
  def get(url, stream: path_to_file) do
    path_to_file = to_string(path_to_file)

    with %URI{path: "" <> url_path} <- URI.parse(url),
         fixture_path <- Path.join(@fixtures_path, url_path),
         true <- File.exists?(fixture_path),
         :ok <- File.cp(fixture_path, path_to_file) do
      :ok
    else
      %URI{path: nil} ->
        {:error, :invalid_request}

      false ->
        %{status: 404, headers: [], body: "Not Found"}

      {:error, error} ->
        {:error, error}
    end
  end

  def get(_, _), do: {:error, :bad_request}
end
