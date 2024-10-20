defmodule Thumbtack.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Query
      import Thumbtack.TestCase
      import Thumbtack.Factory
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Thumbtack.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  setup_all _tags do
    prev_config = Application.get_all_env(:thumbtack)

    Application.put_env(:thumbtack, :repo, Thumbtack.Repo)
    Application.put_env(:thumbtack, :storage, Thumbtack.Storage.Local)
    Application.put_env(:thumbtack, Thumbtack.Storage.Local,
      root_url: "http://localhost:4000/uploads",
      storage_path: "tmp/uploads"
    )

    on_exit(fn ->
      Application.put_all_env(thumbtack: prev_config)
    end)

    :ok
  end

  #
  # A helper that transforms changeset errors into a map of messages.
  #
  #     assert {:error, changeset} = Accounts.create_user(%{password: "short"})
  #     assert "password is too short" in errors_on(changeset).password
  #     assert %{password: ["password is too short"]} = errors_on(changeset)
  #
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  #
  # Image fixtures:
  #   test/fixtures/
  #     corrupted.jpg       - corrupted file
  #     photo-small.jpg     - 322x128
  #     photo-square.heic   - 512x512
  #     photo-tall.png      - 256x718
  #     photo-wide.jpg      - 800x318
  #
  def load_image_fixture(filename) do
    {:ok, image} =
      Path.join(["test/fixtures", filename])
      |> Vix.Vips.Image.new_from_file()

    image
  end
end
