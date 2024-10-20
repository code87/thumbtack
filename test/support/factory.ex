defmodule Thumbtack.Factory do
  @moduledoc false

  alias Thumbtack.Repo

  alias Thumbtack.Album
  alias Thumbtack.User

  def insert(model, attrs \\ %{})

  def insert(:user, attrs) do
    {:ok, user} =
      %User{}
      |> User.changeset(Map.merge(attrs, %{email: "mail@server.com"}))
      |> Repo.insert()

    user
  end

  def insert(:album, attrs) do
    {:ok, album} =
      %Album{}
      |> Album.changeset(Map.merge(attrs, %{title: "My Album"}))
      |> Repo.insert()

    album
  end
end
