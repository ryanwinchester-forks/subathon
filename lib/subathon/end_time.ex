defmodule Subathon.EndTime do
  use Subathon.Schema

  import Ecto.Changeset

  schema "end_times" do
    field :end_time, :utc_datetime_usec
    timestamps(updated_at: false)
  end

  @doc false
  def changeset(end_time, attrs) do
    end_time
    |> cast(attrs, [:end_time])
  end
end
