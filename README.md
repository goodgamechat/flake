# Flake

Generates a [Snowflake](https://en.wikipedia.org/wiki/Snowflake_ID) ID. This implementation is slightly different than the original
snowflake ID but still maintains its most important characteristics: 64-bit integer, unique ID generation within a
distributed cluster, and timestamp sortable.

## Usage
To generate a flake ID, you must explicitly "start" the system. This is separate from the typical BEAM
application startup. The flake application needs to know what the assigned machine ID is, as well as
how many worker processes to create. *You can't create more than 64 workers.*
```elixir
Flake.start(0, 20) # assigns a machine id of 0 and creates 20 worker processes
Flake.start(0)     # assigns a machine id of 0 and defaults to the number of System.schedulers()
```

After starting up, you can generate a flake ID with:
```elixir
{:ok, flake} = Flake.get_id(20)
```
As a performance optimization, you must explicitly request which worker to generate an id. If you started with
20 worker processes, then the valid range is 1 - 20, inclusive. For troubleshooting or general testing,
you can get a breakdown of the flake components as a map:
```elixir
# returns %{time: timestamp, machine_id: machine_id, worker_id: worker_id, counter: counter}
components =
    Flake.get_id(20)
    |> Flake.get_flake_components()
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flake` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flake, "~> 0.1.0"}
  ]
end
```

## Implementation
Flake ID's are 64-bit, unsigned integers broken down into four separate components:

| Name       | Bits |
| ---------- | ---- |
| timestamp  | 34   |
| machine id | 8    |
| worker id  | 6    |
| counter    | 16   |

## Performance
Performance testing was performed on an Apple M3 Pro, 18GB memory, 11 cores.

Used the following script for testing:
```elixir
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
```
The test consistently yields a result of 0.59 seconds per 1,000,000 ID's, about 1.6 - 1.7
million per second. Theoretically, since no consensus is involved in generating an ID, adding servers would multiply
this result. More results will be posted in the future.
