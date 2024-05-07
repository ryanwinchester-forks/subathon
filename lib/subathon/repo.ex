defmodule Subathon.Repo do
  use Ecto.Repo,
    otp_app: :subathon,
    adapter: Ecto.Adapters.Postgres
end
