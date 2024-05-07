defmodule SubathonWeb.Router do
  use SubathonWeb, :router

  import SubathonWeb.ProfileAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SubathonWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_profile
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SubathonWeb do
    pipe_through [:browser]

    live_session :current_profile,
      on_mount: [{SubathonWeb.ProfileAuth, :mount_current_profile}] do
        live "/", PageLive, :index
    end
  end

  # scope "/", SubathonWeb do
  #   pipe_through [:browser, :require_authenticated_profile]
  #
  #   live_session :require_authenticated_profile,
  #     on_mount: [{SubathonWeb.ProfileAuth, :ensure_authenticated}] do
  #       # TODO? Any routes require authentication?
  #   end
  # end

  scope "/auth", SubathonWeb do
    pipe_through [:browser, :redirect_if_profile_is_authenticated]
    get "/", ProfileAuthController, :request
    get "/callback", ProfileAuthController, :callback
  end

  scope "/auth", SubathonWeb do
    pipe_through [:browser, :require_authenticated_profile]
    get "/logout", ProfileSessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", SubathonWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:subathon, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SubathonWeb.Telemetry
    end
  end
end
