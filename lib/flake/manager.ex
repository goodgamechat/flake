defmodule Flake.Manager do
  require Logger
  use GenServer

  defmodule State do
    defstruct started: false,
      machine_id: nil,
      total_workers: 0,
      workers: %{},
      counter: 0
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_id(worker) do
    case :ets.lookup(__MODULE__, worker) do
      [{_, pid}] ->
        Flake.Worker.get_id(pid)
      [] ->
        {:error, :invalid_worker_id}
    end
  end

  def reset() do
    GenServer.call(__MODULE__, :reset, :infinity)
  end

  def start(machine_id, workers) do
    if valid_machine_id(machine_id) do
      GenServer.call(__MODULE__, {:start, machine_id, workers})
    else
      Logger.error "machine_id must be an integer between 0 and 255"
      {:error, :machine_id}
    end
  end

  def init([]) do
    Process.flag(:trap_exit, true)
    :ets.new(__MODULE__, [:protected, :named_table, {:read_concurrency, true}])
    {:ok, %State{}}
  end

  def handle_call({:start, _machine_id, _workers}, _from, %State{started: true} = state) do
    {:reply, {:error, :already_started}, state}
  end

  def handle_call({:start, machine_id, total_workers}, _from, state) do
    workers = for index <- 0..(total_workers - 1), into: %{} do
      pid = create_worker(machine_id, index)
      :ets.insert(__MODULE__, {index, pid})
      {pid, index}
    end

    Logger.info "Started flake service with #{total_workers} workers and machine id of #{machine_id}."

    new_state = %State{state |
      machine_id: machine_id,
      started: true,
      total_workers: total_workers,
      workers: workers
    }
    {:reply, :ok, new_state}
  end

  def handle_call(:reset, _from, state) do
    :ets.delete_all_objects(__MODULE__)
    for {pid, _index} <- state.workers do
      terminate_worker(pid)
    end

    Logger.warning "Flake manager has been reset"
    {:reply, :ok, %State{}}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    id = Map.get(state.workers, pid)
    :ets.delete(__MODULE__, id)
    new_pid = create_worker(state.machine_id, id)
    new_workers = state.workers
      |> Map.delete(pid)
      |> Map.put(new_pid, id)
    :ets.insert(__MODULE__, {id, new_pid})
    {:noreply, %{state | workers: new_workers}}
  end

  defp terminate_worker(pid) do
    Flake.Worker.reset(pid)
    receive do
      {:EXIT, ^pid, {:shutdown, :reset}} ->
        :ok
    end
  end

  defp valid_machine_id(machine_id) when is_integer(machine_id)
    and machine_id >= 0
    and machine_id < 256 do
      true
  end

  defp valid_machine_id(_id) do
    false
  end

  defp create_worker(machine_id, worker) do
    {:ok, pid} = Flake.WorkerSupervisor.start_child(machine_id, worker)
    Process.link(pid)
    pid
  end
end
