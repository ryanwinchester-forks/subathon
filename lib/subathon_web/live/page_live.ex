defmodule SubathonWeb.PageLive do
  use SubathonWeb, :live_view

  alias Subathon.Accounts
  alias Subathon.Accounts.Profile
  alias Subathon.Repo

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Subathon.subscribe("check_ins")
    end

    date_nz = DateTime.now!("Pacific/Auckland") |> DateTime.to_date()

    check_ins =
      Accounts.list_check_ins()
      |> Repo.preload([:profile])
      |> Enum.group_by(& &1.date_nz)

    socket =
      socket
      |> assign(:check_ins, check_ins)
      |> assign(:date_nz, date_nz)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"check-in" => _}, _url, socket) do
    socket =
      socket
      |> do_check_in(socket.assigns.current_profile)
      |> push_patch(to: ~p"/", replace: true)

    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("check-in", _params, socket) do
    case socket.assigns.current_profile do
      nil ->
        Logger.debug("Redirecting???")
        {:noreply, redirect(socket, to: ~p"/auth?check-in")}

      %Profile{} = profile ->
        {:noreply, do_check_in(socket, profile)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:new_check_in, check_in_id}, socket) do
    check_in =
      check_in_id
      |> Accounts.get_check_in!()
      |> Repo.preload([:profile])

    socket =
      update(
        socket,
        :check_ins,
        &Map.update(&1, check_in.date_nz, [check_in], fn check_ins ->
          [check_in | check_ins]
        end)
      )

    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp do_check_in(socket, profile) do
    case Accounts.create_check_in(profile.id) do
      {:ok, _check_in} ->
        Logger.info("Checked in user: #{profile.twitch_username}")
        socket

      {:error, changeset} ->
        Logger.error("Could not check in user: #{inspect(changeset)}")
        put_flash(socket, :error, "couldn't check in")
    end
  end

  defp checked_in?(_check_ins, nil), do: false

  defp checked_in?(check_ins, %Profile{id: profile_id}) do
    Enum.any?(check_ins, &(&1.profile_id == profile_id))
  end
end
