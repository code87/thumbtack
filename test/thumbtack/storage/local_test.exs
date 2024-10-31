defmodule Thumbtack.Storage.LocalTest do
  alias Thumbtack.Storage

  use Thumbtack.TestCase

  # see test/support/test_case.ex
  describe "configuration" do
    test "root_url/0 returns configured root url" do
      assert "http://localhost:4000/uploads" == Storage.Local.root_url()
    end

    test "storage_path/0 returns configured path" do
      assert "tmp/uploads" == Storage.Local.storage_path()
    end
  end

  describe "put(src_path, dest_path)" do
    setup do
      src_path = System.tmp_dir() |> Path.join("dummy-file.txt")

      :ok = File.write(src_path, "Dummy file content")

      on_exit(fn ->
        :ok = File.rm(src_path)
      end)

      {:ok, src_path: src_path}
    end

    test "copies existing file and returns URL", %{src_path: src_path} do
      assert {:ok, "http://localhost:4000/uploads/dummy/file.txt"} =
               Storage.Local.put(src_path, "/dummy/file.txt")

      assert {:ok, "Dummy file content"} = File.read("tmp/uploads/dummy/file.txt")
    end

    test "returns error tuple if source file does not exist" do
      src_path = System.tmp_dir() |> Path.join("unknown.txt")
      assert {:error, :enoent} = Storage.Local.put(src_path, "/dummy/file.txt")
    end

    test "returns error tuple if src_path is not a file path" do
      src_path = System.tmp_dir()
      assert {:error, _reason} = Storage.Local.put(src_path, "/dummy/file.txt")
    end
  end

  describe "delete(path)" do
    test "deletes existing file and returns URL" do
      :ok = File.mkdir_p("tmp/uploads/dummy")
      :ok = File.write("tmp/uploads/dummy/file.txt", "Dummy content")

      assert {:ok, "http://localhost:4000/uploads/dummy/file.txt"} =
               Storage.Local.delete("/dummy/file.txt")

      refute File.exists?("tmp/uploads/dummy/file.txt")
    end

    test "returns error tuple if file does not exist" do
      refute File.exists?("tmp/uploads/dummy/unknown.txt")
      assert {:error, :enoent} = Storage.Local.delete("dummy/unknown.txt")
    end
  end

  describe "delete_folder(path)" do
    test "deletes existing folder and returns :ok" do
      :ok = File.mkdir_p("tmp/uploads/dummy")
      :ok = File.write("tmp/uploads/dummy/file.txt", "Dummy content")

      assert :ok = Storage.Local.delete_folder("/dummy")
      refute File.exists?("tmp/uploads/dummy")
    end

    test "deletes existing folder with files and subfolders and returns :ok" do
      :ok = File.mkdir_p("tmp/uploads/folder-with-files")
      :ok = File.write("tmp/uploads/folder-with-files/file.txt", "Dummy content")
      :ok = File.mkdir_p("tmp/uploads/folder-with-files/subfolder")
      :ok = File.write("tmp/uploads/folder-with-files/subfolder/file.txt", "Dummy content")

      assert :ok = Storage.Local.delete_folder("/folder-with-files/file.txt")
      refute File.exists?("tmp/uploads/folder-with-files")
    end

    test "returns error tuple if folder does not exist" do
      refute File.exists?("tmp/uploads/non-existing-folder")
      assert {:error, :enoent} = Storage.Local.delete_folder("/non-existing-folder")
    end

    test "returns error on attempt to remove storage root" do
      assert {:error, :enoent} = Storage.Local.delete_folder("")
      assert File.exists?("tmp/uploads")
    end
  end
end
