defmodule SubathonWeb.ProfileConfirmationInstructionsLiveTest do
  use SubathonWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Subathon.AccountsFixtures

  alias Subathon.Accounts
  alias Subathon.Repo

  setup do
    %{profile: profile_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profiles/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, profile: profile} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", profile: %{email: profile.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.ProfileToken, profile_id: profile.id).context == "confirm"
    end

    test "does not send confirmation token if profile is confirmed", %{conn: conn, profile: profile} do
      Repo.update!(Accounts.Profile.confirm_changeset(profile))

      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", profile: %{email: profile.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.ProfileToken, profile_id: profile.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", profile: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.ProfileToken) == []
    end
  end
end
