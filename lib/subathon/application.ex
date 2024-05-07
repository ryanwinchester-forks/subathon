defmodule Subathon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SubathonWeb.Telemetry,
      Subathon.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:subathon, :ecto_repos),
       skip: System.get_env("SKIP_MIGRATIONS") == "true"},
      {DNSCluster, query: Application.get_env(:subathon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Subathon.PubSub},
      # Start a worker by calling: Subathon.Worker.start_link(arg)
      # {Subathon.Worker, arg},
      # Start to serve requests, typically the last entry
      SubathonWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subathon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SubathonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
