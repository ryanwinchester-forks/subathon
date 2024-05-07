defmodule SubathonWeb.ProfileSessionController do
  use SubathonWeb, :controller

  alias SubathonWeb.ProfileAuth

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> ProfileAuth.logout_profile()
  end
end
