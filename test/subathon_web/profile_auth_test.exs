defmodule SubathonWeb.ProfileAuthTest do
  use SubathonWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Subathon.Accounts
  alias SubathonWeb.ProfileAuth
  import Subathon.AccountsFixtures

  @remember_me_cookie "_subathon_web_profile_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, SubathonWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{profile: profile_fixture(), conn: conn}
  end

  describe "log_in_profile/3" do
    test "stores the profile token in the session", %{conn: conn, profile: profile} do
      conn = ProfileAuth.log_in_profile(conn, profile)
      assert token = get_session(conn, :profile_token)
      assert get_session(conn, :live_socket_id) == "profiles_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_profile_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, profile: profile} do
      conn = conn |> put_session(:to_be_removed, "value") |> ProfileAuth.log_in_profile(profile)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, profile: profile} do
      conn = conn |> put_session(:profile_return_to, "/hello") |> ProfileAuth.log_in_profile(profile)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, profile: profile} do
      conn = conn |> fetch_cookies() |> ProfileAuth.log_in_profile(profile, %{"remember_me" => "true"})
      assert get_session(conn, :profile_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :profile_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_profile/1" do
    test "erases session and cookies", %{conn: conn, profile: profile} do
      profile_token = Accounts.generate_profile_session_token(profile)

      conn =
        conn
        |> put_session(:profile_token, profile_token)
        |> put_req_cookie(@remember_me_cookie, profile_token)
        |> fetch_cookies()
        |> ProfileAuth.log_out_profile()

      refute get_session(conn, :profile_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_profile_by_session_token(profile_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "profiles_sessions:abcdef-token"
      SubathonWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> ProfileAuth.log_out_profile()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if profile is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> ProfileAuth.log_out_profile()
      refute get_session(conn, :profile_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_profile/2" do
    test "authenticates profile from session", %{conn: conn, profile: profile} do
      profile_token = Accounts.generate_profile_session_token(profile)
      conn = conn |> put_session(:profile_token, profile_token) |> ProfileAuth.fetch_current_profile([])
      assert conn.assigns.current_profile.id == profile.id
    end

    test "authenticates profile from cookies", %{conn: conn, profile: profile} do
      logged_in_conn =
        conn |> fetch_cookies() |> ProfileAuth.log_in_profile(profile, %{"remember_me" => "true"})

      profile_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> ProfileAuth.fetch_current_profile([])

      assert conn.assigns.current_profile.id == profile.id
      assert get_session(conn, :profile_token) == profile_token

      assert get_session(conn, :live_socket_id) ==
               "profiles_sessions:#{Base.url_encode64(profile_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, profile: profile} do
      _ = Accounts.generate_profile_session_token(profile)
      conn = ProfileAuth.fetch_current_profile(conn, [])
      refute get_session(conn, :profile_token)
      refute conn.assigns.current_profile
    end
  end

  describe "on_mount :mount_current_profile" do
    test "assigns current_profile based on a valid profile_token", %{conn: conn, profile: profile} do
      profile_token = Accounts.generate_profile_session_token(profile)
      session = conn |> put_session(:profile_token, profile_token) |> get_session()

      {:cont, updated_socket} =
        ProfileAuth.on_mount(:mount_current_profile, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_profile.id == profile.id
    end

    test "assigns nil to current_profile assign if there isn't a valid profile_token", %{conn: conn} do
      profile_token = "invalid_token"
      session = conn |> put_session(:profile_token, profile_token) |> get_session()

      {:cont, updated_socket} =
        ProfileAuth.on_mount(:mount_current_profile, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_profile == nil
    end

    test "assigns nil to current_profile assign if there isn't a profile_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        ProfileAuth.on_mount(:mount_current_profile, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_profile == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_profile based on a valid profile_token", %{conn: conn, profile: profile} do
      profile_token = Accounts.generate_profile_session_token(profile)
      session = conn |> put_session(:profile_token, profile_token) |> get_session()

      {:cont, updated_socket} =
        ProfileAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_profile.id == profile.id
    end

    test "redirects to login page if there isn't a valid profile_token", %{conn: conn} do
      profile_token = "invalid_token"
      session = conn |> put_session(:profile_token, profile_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: SubathonWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ProfileAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_profile == nil
    end

    test "redirects to login page if there isn't a profile_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: SubathonWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ProfileAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_profile == nil
    end
  end

  describe "on_mount :redirect_if_profile_is_authenticated" do
    test "redirects if there is an authenticated  profile ", %{conn: conn, profile: profile} do
      profile_token = Accounts.generate_profile_session_token(profile)
      session = conn |> put_session(:profile_token, profile_token) |> get_session()

      assert {:halt, _updated_socket} =
               ProfileAuth.on_mount(
                 :redirect_if_profile_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated profile", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               ProfileAuth.on_mount(
                 :redirect_if_profile_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_profile_is_authenticated/2" do
    test "redirects if profile is authenticated", %{conn: conn, profile: profile} do
      conn = conn |> assign(:current_profile, profile) |> ProfileAuth.redirect_if_profile_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if profile is not authenticated", %{conn: conn} do
      conn = ProfileAuth.redirect_if_profile_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_profile/2" do
    test "redirects if profile is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> ProfileAuth.require_authenticated_profile([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/profiles/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> ProfileAuth.require_authenticated_profile([])

      assert halted_conn.halted
      assert get_session(halted_conn, :profile_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> ProfileAuth.require_authenticated_profile([])

      assert halted_conn.halted
      assert get_session(halted_conn, :profile_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> ProfileAuth.require_authenticated_profile([])

      assert halted_conn.halted
      refute get_session(halted_conn, :profile_return_to)
    end

    test "does not redirect if profile is authenticated", %{conn: conn, profile: profile} do
      conn = conn |> assign(:current_profile, profile) |> ProfileAuth.require_authenticated_profile([])
      refute conn.halted
      refute conn.status
    end
  end
end
