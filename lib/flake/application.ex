defmodule Flake.Application do
  use Application

  def start(_type, _args) do
    Flake.Supervisor.start_link()
  end
end
