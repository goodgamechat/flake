defmodule Flake do
  require Logger

  def start(machine_id, workers) when is_integer(workers) and workers > 0 and workers <= 64 do
    Flake.Manager.start(machine_id, workers)
  end

  def start(_machine_id, _workers) do
    Logger.error("The parameter 'workers' needs to be an integer between 1 and 64.")
    {:error, :invalid_workers}
  end

  def start(machine_id) do
    Flake.Manager.start(machine_id, :erlang.min(64, System.schedulers()))
  end

  def get_id(worker_id) do
    case Flake.Manager.get_id(worker_id) do
      {:ok, _id} = flake ->
        flake

      {:error, :potential_duplicate_id} ->
        # last ditch effort
        :timer.sleep(:timer.seconds(1))
        Flake.Manager.get_id(worker_id)

      other ->
        other
    end
  end

  def get_flake_components({:ok, flake}) do
    get_flake_components(flake)
  end

  def get_flake_components(flake) do
    <<time::34, machine_id::8, worker_id::6, counter::16>> = <<flake::64>>
    %{time: time, machine_id: machine_id, worker_id: worker_id, counter: counter}
  end
end
