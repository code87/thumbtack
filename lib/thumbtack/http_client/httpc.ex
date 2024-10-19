defmodule Thumbtack.HttpClient.Httpc do
  @moduledoc false

  @typep header :: {header :: String.t(), content :: String.t()}
  @typep response ::
           :ok
           | %{:status => integer(), :headers => [header()], :body => binary()}
           | {:error, term()}

  @spec get(url :: String.t(), opts :: keyword()) :: response
  def get(url, opts \\ []) do
    headers = []

    # coveralls-ignore-start
    http_request_opts = [
      ssl: [
        cacerts: :public_key.cacerts_get(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    result = :httpc.request(:get, {url, headers}, http_request_opts, opts)
    # coveralls-ignore-stop

    case result do
      {:ok, :saved_to_file} ->
        :ok

      {:ok, {_status_line, _headers, _body} = response} ->
        parse_response(response)

      {:error, term} ->
        {:error, term}
    end
  end

  defp parse_response({status_line, headers, body}) do
    {_version, code, _string} = status_line

    %{
      status: code,
      headers:
        Enum.map(headers, fn {header, content} -> {to_string(header), to_string(content)} end),
      body: :erlang.list_to_binary(body)
    }
  end
end
