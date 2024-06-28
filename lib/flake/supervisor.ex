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

defmodule Flake.Supervisor do
  use Supervisor
  @moduledoc false

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
