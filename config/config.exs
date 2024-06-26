if Mix.env() == :test do
  import Config

  config :flake,
    machine_id: 1
end
