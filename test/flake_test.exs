defmodule FlakeTest do
  use ExUnit.Case, async: true

  setup do
    Flake.Manager.reset()
  end

  test "can generate a flake id for a given worker id" do
    Flake.start(1)
    components = Flake.get_id(1) |> Flake.get_flake_components()
    assert components.machine_id == 1
    assert components.worker_id == 1
    assert components.counter == 0
  end

  test "counter restart doesnt allow duplicate flake ids" do
    Flake.start(0)

    results =
      for _i <- 1..100_000 do
        {:ok, flake} = Flake.get_id(0)
        flake
      end

    count =
      results
      |> Enum.uniq()
      |> Enum.count()

    assert count == 100_000
  end

  test "flake manager resets worker" do
    Flake.start(0, 1)
    flake = Flake.get_id(0) |> Flake.get_flake_components()
    state = :sys.get_state(Flake.Manager)

    [{pid, id}] =
      state.workers
      |> Map.to_list()

    ref = :erlang.monitor(:process, pid)
    :erlang.exit(pid, :kill)

    receive do
      {:DOWN, ^ref, :process, _, _} -> :ok
    end

    state = :sys.get_state(Flake.Manager)

    [{new_pid, ^id}] =
      state.workers
      |> Map.to_list()

    flake2 = Flake.get_id(0) |> Flake.get_flake_components()
    refute pid == new_pid
    assert flake.worker_id == flake2.worker_id
  end

  test "can't start Flake with more than 64 workers" do
    refute Flake.start(1, 65) == :ok
    refute Flake.start(1, -1) == :ok
    refute Flake.start(1, :foo) == :ok
  end

  test "can't start Flake with invalid machine id" do
    refute Flake.start(-1) == :ok
    refute Flake.start(:foo) == :ok
    refute Flake.start(256) == :ok
  end

  test "can generate 1,000,000 ids within a couple of seconds" do
    workers = 20
    work = div(1_000_000, workers)
    Flake.start(1, workers)

    {time, ids} =
      :timer.tc(fn ->
        ts =
          for j <- 0..(workers - 1),
              do:
                Task.async(fn ->
                  for _i <- 1..work do
                    {:ok, id} = Flake.get_id(j)
                    id
                  end
                end)

        for t <- ts, do: Task.await(t)
      end)

    total =
      ids
      |> List.flatten()
      |> Enum.count()

    IO.puts("Took #{time / 1000 / 1000} seconds to generate #{work * workers} ids.")
    assert total == 1_000_000
    assert time < :timer.seconds(3) * 1000
  end
end
