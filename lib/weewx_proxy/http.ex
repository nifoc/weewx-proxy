defmodule WeewxProxy.Http do
  @moduledoc false

  use Supervisor

  @name __MODULE__

  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  # Callbacks

  @impl true
  def init([]) do
    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: WeewxProxy.HTTP.Ecowitt,
       options: [
         port: 4040,
         transport_options: [
           num_acceptors: 3
         ]
       ]},
      {Plug.Cowboy.Drainer, refs: [WeewxProxy.HTTP.Ecowitt.HTTP]},
      WeewxProxy.HTTP.PurpleAir
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
