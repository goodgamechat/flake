###----------------------------------------------------------------------------
###
###  flake, Copyright (C) 2024  Michael Slezak
###
###  This program is free software: you can redistribute it and/or modify
###  it under the terms of the GNU General Public License as published by
###  the Free Software Foundation, either version 3 of the License, or
###  (at your option) any later version.
###
###  This program is distributed in the hope that it will be useful,
###  but WITHOUT ANY WARRANTY; without even the implied warranty of
###  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
###  GNU General Public License for more details.
###
###  You should have received a copy of the GNU General Public License
###  along with this program.  If not, see <https://www.gnu.org/licenses/>.
###
###----------------------------------------------------------------------------

defmodule Flake do
  @type flake_id()   :: 0..18_446_744_073_709_551_615
  @type machine_id() :: 0..255
  @type worker_id()  :: 0..63

  @moduledoc """
  Public-facing API for starting and generating flake ID's.
  """
  require Logger

  @doc """
  Creates worker processes and assigns the application's machine ID to all workers.

  This *must* be called before generating a flake ID.
  """
  @spec start(machine_id(), workers) :: :ok | {:error, error} when
    workers: 1..64,
    error: :machine_id
         | :invalid_workers
         | :already_started
  def start(machine_id, workers) when is_integer(workers) and workers > 0 and workers <= 64 do
    Flake.Manager.start(machine_id, workers)
  end

  def start(_machine_id, _workers) do
    Logger.error("The parameter 'workers' needs to be an integer between 1 and 64.")
    {:error, :invalid_workers}
  end

  @doc """
  Creates worker processes and assigns the application's machine ID to all workers.

  The number of worker processes defaults to the number of BEAM schedulers, or 64,
  whichever is less.

  This *must* be called before generating a flake ID.
  """
  @spec start(machine_id()) :: :ok | {:error, error} when
    error: :machine_id
         | :already_started
  def start(machine_id) do
    Flake.Manager.start(machine_id, :erlang.min(64, System.schedulers()))
  end

  @doc """
  Generates a 64-bit unsigned integer flake ID given a worker ID.

  Worker ID must be within the range of 0..(N-1), where N is the total number of workers
  passed in to the `start/1` or `start/2` functions.

  For best performance, try to evenly distribute calls to flake worker processes from
  different calling processes.
  """
  @spec get_id(worker_id()) :: {:ok, flake_id()} | {:error, error} when
    error: :potential_duplicate_id
         | :invalid_worker_id
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

  @doc """
  Given a flake ID, return a map that breaks down the different components of the flake ID.

  This is particularly useful for troubleshooting or for use in automated tests.

  ## Examples
  ```elixir
  iex> Flake.get_flake_components(1846405654575644672)
  %{time: 1719599268, machine_id: 1, worker_id: 1, counter: 0}
  ```
  """
  @spec get_flake_components({:ok, flake_id()} | flake_id()) :: results when
    results: %{required(:time)       => 0..17_179_869_183,
               required(:machine_id) => machine_id(),
               required(:worker_id)  =>  worker_id(),
               required(:counter)    => 0..65_535}
  def get_flake_components({:ok, flake}) do
    get_flake_components(flake)
  end

  def get_flake_components(flake) do
    <<time::34, machine_id::8, worker_id::6, counter::16>> = <<flake::64>>
    %{time: time, machine_id: machine_id, worker_id: worker_id, counter: counter}
  end
end
