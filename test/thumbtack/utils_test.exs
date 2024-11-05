defmodule Thumbtack.UtilsTest do
  use Thumbtack.TestCase

  alias Thumbtack.Utils

  describe "generate_tempfile_path(extension)" do
    test "generates tempfile path in system tmp directory" do
      assert String.starts_with?(Utils.generate_tempfile_path(), System.tmp_dir())
    end

    test "adds extension" do
      assert String.ends_with?(Utils.generate_tempfile_path(".jpg"), ".jpg")
    end
  end

  describe "timestamp" do
    test "returns current UTC time" do
      assert DateTime.utc_now() |> DateTime.truncate(:second) == Utils.timestamp()
    end
  end

  describe "convert_date_time_to_timestamp(date_time)" do
    test "converts DateTime to timestamp" do
      date_time = DateTime.utc_now()

      assert Integer.to_string(DateTime.to_unix(date_time)) ==
               Utils.convert_date_time_to_timestamp(date_time)
    end
  end
end
