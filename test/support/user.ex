defmodule Thumbtack.User do
  @moduledoc false

  import Ecto.Changeset

  use Ecto.Schema

  schema "users" do
    field :email, :string
    # has_one :photo, UserPhoto
  end

  def changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
