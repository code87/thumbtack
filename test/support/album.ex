defmodule Thumbtack.Album do
  @moduledoc false

  import Ecto.Changeset

  use Ecto.Schema

  schema "albums" do
    field :title, :string
    # has_many :photos, AlbumPhoto
  end

  def changeset(%__MODULE__{} = album, attrs \\ %{}) do
    album
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end
