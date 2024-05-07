defmodule SubathonWeb.ProfileForgotPasswordLiveTest do
  use SubathonWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Subathon.AccountsFixtures

  alias Subathon.Accounts
  alias Subathon.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/profiles/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/profiles/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/profiles/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_profile(profile_fixture())
        |> live(~p"/profiles/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{profile: profile_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, profile: profile} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", profile: %{"email" => profile.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Accounts.ProfileToken, profile_id: profile.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", profile: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.ProfileToken) == []
    end
  end
end
