defmodule Flake.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(machine_id, worker_id) do
    DynamicSupervisor.start_child(__MODULE__, {Flake.Worker, [machine_id, worker_id]})
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, intensity: 128)
  end
end
