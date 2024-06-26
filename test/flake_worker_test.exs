defmodule FlakeWorkerTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = Flake.Worker.start_link([1, 1])
    {:ok, pid: pid}
  end

  test "counter restarts after max number", context do
    for _i <- 0..65_535 do
      {:ok, _flake} = Flake.Worker.get_id(context.pid)
    end

    :timer.sleep(:timer.seconds(1))
    last_flake = Flake.Worker.get_id(context.pid) |> Flake.get_flake_components()
    assert last_flake.counter == 0
  end
end
