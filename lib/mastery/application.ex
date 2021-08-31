defmodule Mastery.Application do
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Mastery")

    servers = %{
      proctor: Mastery.Boundary.Proctor,
      quiz_manager: Mastery.Boundary.QuizManager
    }

    children = [
      {Mastery.Boundary.QuizManager, [name: servers.quiz_manager]},
      {Registry, [name: Mastery.Registry.QuizSession, keys: :unique]},
      {Mastery.Boundary.Proctor, [name: servers.proctor, servers: servers]},
      {
        DynamicSupervisor,
        [
          name: Mastery.Supervisor.QuizSession,
          strategy: :one_for_one,
          extra_arguments: [:dummy]
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: Mastery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
