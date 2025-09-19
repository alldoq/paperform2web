defmodule Paperform2web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Paperform2webWeb.Telemetry,
      Paperform2web.Repo,
      {DNSCluster, query: Application.get_env(:paperform2web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Paperform2web.PubSub},
      # Start a worker by calling: Paperform2web.Worker.start_link(arg)
      # {Paperform2web.Worker, arg},
      # Start to serve requests, typically the last entry
      Paperform2webWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Paperform2web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Paperform2webWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
