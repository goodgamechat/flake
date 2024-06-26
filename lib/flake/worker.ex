defmodule Flake.Worker do
  use GenServer, restart: :temporary

  @max_worker_id 64
  @max_counter 65_536

  defmodule State do
    defstruct worker_id: nil,
              machine_id: nil,
              counter: 0,
              total_calls: 0,
              last_flake: 0
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def reset(pid) do
    GenServer.cast(pid, :reset)
  end

  def get_id(pid) do
    GenServer.call(pid, :get_id)
  end

  def init([machine_id, id]) when id <= @max_worker_id do
    {:ok, %State{machine_id: machine_id, worker_id: id}}
  end

  def init(_args) do
    {:stop, :exceeded_max_worker_id}
  end

  def handle_call(:get_id, _from, state) do
    time = :erlang.system_time(:seconds)
    <<flake_id::64-unsigned-integer>> = <<time::34, state.machine_id::8, state.worker_id::6, state.counter::16>>

    if flake_id > state.last_flake do
      new_state = %State{
        state
        | counter: rem(state.counter + 1, @max_counter),
          total_calls: state.total_calls + 1,
          last_flake: flake_id
      }

      {:reply, {:ok, flake_id}, new_state}
    else
      {:reply, {:error, :potential_duplicate_id}, state}
    end
  end

  def handle_cast(:reset, state) do
    {:stop, {:shutdown, :reset}, state}
  end
end
