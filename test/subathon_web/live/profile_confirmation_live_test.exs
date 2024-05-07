defmodule SubathonWeb.ProfileConfirmationLiveTest do
  use SubathonWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Subathon.AccountsFixtures

  alias Subathon.Accounts
  alias Subathon.Repo

  setup do
    %{profile: profile_fixture()}
  end

  describe "Confirm profile" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profiles/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, profile: profile} do
      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_confirmation_instructions(profile, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Profile confirmed successfully"

      assert Accounts.get_profile!(profile.id).confirmed_at
      refute get_session(conn, :profile_token)
      assert Repo.all(Accounts.ProfileToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Profile confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_profile(profile)

      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, profile: profile} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Profile confirmation link is invalid or it has expired"

      refute Accounts.get_profile!(profile.id).confirmed_at
    end
  end
end
