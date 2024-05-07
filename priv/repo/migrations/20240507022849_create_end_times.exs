defmodule Subathon.Repo.Migrations.CreateEndTimes do
  use Ecto.Migration

  def change do
    create table(:end_times) do
      add :end_time, :utc_datetime_usec, null: false, default: fragment("now()")
      timestamps(updated_at: false)
    end
  end
end
