defmodule ThumbtackTest do
  use Thumbtack.TestCase

  # see test/support/test_case.ex
  describe "repo()" do
    test "returns configured Ecto repo" do
      assert Thumbtack.Repo == Thumbtack.repo()
    end
  end

  # see test/support/test_case.ex
  describe "storage()" do
    test "returns configured storage module" do
      assert Thumbtack.Storage.Local == Thumbtack.storage()
    end
  end
end
