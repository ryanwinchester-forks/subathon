defmodule SubathonWeb.ProfileSessionControllerTest do
  use SubathonWeb.ConnCase, async: true

  import Subathon.AccountsFixtures

  setup do
    %{profile: profile_fixture()}
  end

  describe "POST /profiles/log_in" do
    test "logs the profile in", %{conn: conn, profile: profile} do
      conn =
        post(conn, ~p"/profiles/log_in", %{
          "profile" => %{"email" => profile.email, "password" => valid_profile_password()}
        })

      assert get_session(conn, :profile_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ profile.email
      assert response =~ ~p"/profiles/settings"
      assert response =~ ~p"/profiles/log_out"
    end

    test "logs the profile in with remember me", %{conn: conn, profile: profile} do
      conn =
        post(conn, ~p"/profiles/log_in", %{
          "profile" => %{
            "email" => profile.email,
            "password" => valid_profile_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_subathon_web_profile_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the profile in with return to", %{conn: conn, profile: profile} do
      conn =
        conn
        |> init_test_session(profile_return_to: "/foo/bar")
        |> post(~p"/profiles/log_in", %{
          "profile" => %{
            "email" => profile.email,
            "password" => valid_profile_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, profile: profile} do
      conn =
        conn
        |> post(~p"/profiles/log_in", %{
          "_action" => "registered",
          "profile" => %{
            "email" => profile.email,
            "password" => valid_profile_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, profile: profile} do
      conn =
        conn
        |> post(~p"/profiles/log_in", %{
          "_action" => "password_updated",
          "profile" => %{
            "email" => profile.email,
            "password" => valid_profile_password()
          }
        })

      assert redirected_to(conn) == ~p"/profiles/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/profiles/log_in", %{
          "profile" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/profiles/log_in"
    end
  end

  describe "DELETE /profiles/log_out" do
    test "logs the profile out", %{conn: conn, profile: profile} do
      conn = conn |> log_in_profile(profile) |> delete(~p"/profiles/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :profile_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the profile is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/profiles/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :profile_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
