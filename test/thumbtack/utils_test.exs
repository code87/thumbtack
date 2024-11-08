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

  describe "maybe_append_timestamp(url, date_time)" do
    test "appends timestamp to the URL if date_time is present" do
      url = "http://example.com"
      date_time = Utils.timestamp()

      converted_date_time = date_time |> DateTime.to_unix() |> Integer.to_string()

      assert "#{url}?v=#{converted_date_time}" == Utils.maybe_append_timestamp(url, date_time)
    end

    test "does not append timestamp if date_time is nil" do
      url = "http://example.com"

      assert url == Utils.maybe_append_timestamp(url, nil)
    end
  end
end
