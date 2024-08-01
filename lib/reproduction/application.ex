defmodule Reproduction.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReproductionWeb.Telemetry,
      Reproduction.Repo,
      {DNSCluster, query: Application.get_env(:reproduction, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Reproduction.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Reproduction.Finch},
      # Start a worker by calling: Reproduction.Worker.start_link(arg)
      # {Reproduction.Worker, arg},
      # Start to serve requests, typically the last entry
      ReproductionWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Reproduction.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReproductionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
