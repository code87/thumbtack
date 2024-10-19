defmodule Thumbtack.Utils do
  @moduledoc false

  @spec generate_tempfile_path(extension :: String.t()) :: String.t()
  def generate_tempfile_path(extension \\ "") do
    filename = Ecto.UUID.generate() <> extension

    System.tmp_dir()
    |> Path.join(filename)
  end
end
