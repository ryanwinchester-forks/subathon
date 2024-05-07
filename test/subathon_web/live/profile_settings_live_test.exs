defmodule SubathonWeb.ProfileSettingsLiveTest do
  use SubathonWeb.ConnCase, async: true

  alias Subathon.Accounts
  import Phoenix.LiveViewTest
  import Subathon.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_profile(profile_fixture())
        |> live(~p"/profiles/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if profile is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/profiles/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profiles/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_profile_password()
      profile = profile_fixture(%{password: password})
      %{conn: log_in_profile(conn, profile), profile: profile, password: password}
    end

    test "updates the profile email", %{conn: conn, password: password, profile: profile} do
      new_email = unique_profile_email()

      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "profile" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_profile_by_email(profile.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "profile" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, profile: profile} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "profile" => %{"email" => profile.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_profile_password()
      profile = profile_fixture(%{password: password})
      %{conn: log_in_profile(conn, profile), profile: profile, password: password}
    end

    test "updates the profile password", %{conn: conn, profile: profile, password: password} do
      new_password = valid_profile_password()

      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "profile" => %{
            "email" => profile.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/profiles/settings"

      assert get_session(new_password_conn, :profile_token) != get_session(conn, :profile_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_profile_by_email_and_password(profile.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "profile" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profiles/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "profile" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      profile = profile_fixture()
      email = unique_profile_email()

      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_update_email_instructions(%{profile | email: email}, profile.email, url)
        end)

      %{conn: log_in_profile(conn, profile), token: token, email: email, profile: profile}
    end

    test "updates the profile email once", %{conn: conn, profile: profile, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/profiles/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profiles/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_profile_by_email(profile.email)
      assert Accounts.get_profile_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/profiles/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profiles/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, profile: profile} do
      {:error, redirect} = live(conn, ~p"/profiles/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profiles/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_profile_by_email(profile.email)
    end

    test "redirects if profile is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/profiles/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profiles/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
