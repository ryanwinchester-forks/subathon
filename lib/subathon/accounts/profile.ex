defmodule Subathon.Accounts.Profile do
  use Subathon.Schema

  import Ecto.Changeset

  schema "profiles" do
    field :twitch_id, :string
    field :twitch_username, :string
    field :pfp_url, :string
    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:twitch_id, :twitch_username, :pfp_url])
    |> validate_required([:twitch_id, :twitch_username, :pfp_url])
    |> unique_constraint(:twitch_id)
    |> unique_constraint(:twitch_username)
  end
end
