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
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/dummy")
      end)

      :ok = File.mkdir_p("tmp/uploads/dummy")
      :ok = File.write("tmp/uploads/dummy/file.txt", "Dummy content")

      assert :ok = Storage.Local.delete_folder("/dummy")
      refute File.exists?("tmp/uploads/dummy")
    end

    test "returns error if given path is not folder" do
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/folder-with-files")
      end)

      :ok = File.mkdir_p("tmp/uploads/folder-with-files")
      :ok = File.write("tmp/uploads/folder-with-files/file.txt", "Dummy content")

      assert {:error, :enoent} = Storage.Local.delete_folder("/folder-with-files/file.txt")
    end

    test "returns error tuple if folder does not exist" do
      refute File.exists?("tmp/uploads/non-existing-folder")
      assert {:error, :enoent} = Storage.Local.delete_folder("/non-existing-folder")
    end

    test "returns error on attempt to remove storage root" do
      assert {:error, :enoent} = Storage.Local.delete_folder("")
      assert File.exists?("tmp/uploads")
    end

    test "returns error if nil is given" do
      assert {:error, :enoent} = Storage.Local.delete_folder(nil)
    end
  end

  describe "rename_folder(old_path, new_path)" do
    test "renames existing folder and returns :ok" do
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/new-dummy")
      end)

      :ok = File.mkdir_p("tmp/uploads/dummy")
      :ok = File.write("tmp/uploads/dummy/file.txt", "Dummy content")

      assert :ok = Storage.Local.rename_folder("/dummy", "/new-dummy")
      refute File.exists?("tmp/uploads/dummy")
      assert File.exists?("tmp/uploads/new-dummy")
    end

    test "returns error tuple if folder does not exist" do
      refute File.exists?("tmp/uploads/non-existing-folder")

      assert {:error, :enoent} =
               Storage.Local.rename_folder("/non-existing-folder", "/new-folder")
    end

    test "returns error on attempt to rename storage root" do
      assert {:error, :enoent} = Storage.Local.rename_folder("", "/new-dummy")
      assert File.exists?("tmp/uploads")
    end

    test "retuns error on attempt to rename file" do
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/dummy")
      end)

      :ok = File.mkdir_p("tmp/uploads/dummy")
      :ok = File.write("tmp/uploads/dummy/file.txt", "Dummy content")

      assert {:error, :enoent} = Storage.Local.rename_folder("/dummy/file.txt", "/new-dummy")
    end

    test "returns error if nil is given" do
      assert {:error, :enoent} = Storage.Local.rename_folder(nil, "/new-dummy")
    end

    test "returns error if new path is nil" do
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/dummy")
      end)

      :ok = File.mkdir_p("tmp/uploads/dummy")

      assert {:error, :enoent} = Storage.Local.rename_folder("/dummy", nil)
    end

    test "returns ok if paths are the same without rename" do
      on_exit(fn ->
        {:ok, _} = File.rm_rf("tmp/uploads/dummy")
      end)

      :ok = File.mkdir_p("tmp/uploads/dummy")

      assert {:ok, _} = Storage.Local.rename_folder("/dummy", "/dummy")
    end
  end
end
