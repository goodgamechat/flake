defmodule Flake.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    children = [
      Flake.WorkerSupervisor,
      Flake.Manager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
