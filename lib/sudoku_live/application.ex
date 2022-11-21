defmodule SudokuLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # SudokuLive.Repo,
      # Start the Telemetry supervisor
      SudokuLiveWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SudokuLive.PubSub},
      # Start the Endpoint (http/https)
      SudokuLiveWeb.Endpoint
      # Start a worker by calling: SudokuLive.Worker.start_link(arg)
      # {SudokuLive.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SudokuLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SudokuLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
