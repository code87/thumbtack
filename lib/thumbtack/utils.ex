defmodule Thumbtack.Utils do
  @moduledoc false

  @spec generate_tempfile_path(extension :: String.t()) :: String.t()
  def generate_tempfile_path(extension \\ "") do
    filename = Ecto.UUID.generate() <> extension

    System.tmp_dir()
    |> Path.join(filename)
  end

  @spec timestamp :: DateTime.t()
  @doc """
  Returns current UTC time.
  """
  def timestamp do
    DateTime.now!("Etc/UTC") |> DateTime.truncate(:second)
  end

  @spec convert_date_time_to_timestamp(date_time :: DateTime.t()) :: String.t()
  @doc """
  Converts DateTime to timestamp. Returns timestamp as a string.
  """
  def convert_date_time_to_timestamp(date_time) do
    date_time
    |> DateTime.to_unix()
    |> Integer.to_string()
  end
end
