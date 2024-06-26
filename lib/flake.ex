defmodule Flake do
  require Logger

  def start(machine_id, workers \\ System.schedulers()) do
    Flake.Manager.start(machine_id, :erlang.min(64, workers))
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
