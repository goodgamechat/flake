### ----------------------------------------------------------------------------
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
### ----------------------------------------------------------------------------

defmodule Flake.WorkerSupervisor do
  use DynamicSupervisor
  @moduledoc false

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
