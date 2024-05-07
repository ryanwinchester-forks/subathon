defmodule Subathon.Accounts.CheckIn do
  use Subathon.Schema

  import Ecto.Changeset

  alias Subathon.Accounts.Profile

  schema "check_ins" do
    belongs_to :profile, Profile
    field :date_nz, :date
    field :inserted_at, :utc_datetime_usec
  end

  @doc false
  def changeset(check_in, attrs) do
    check_in
    |> cast(attrs, [])
    |> put_date()
    |> unique_constraint([:profile_id, :date_nz])
  end

  defp put_date(changeset) do
    inserted_at = DateTime.utc_now()

    date_nz =
      inserted_at
      |> DateTime.shift_zone!("Pacific/Auckland")
      |> DateTime.to_date()

    changeset
    |> put_change(:inserted_at, inserted_at)
    |> put_change(:date_nz, date_nz)
  end
end
