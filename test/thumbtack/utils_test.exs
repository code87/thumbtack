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
end
