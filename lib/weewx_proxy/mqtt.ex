defmodule WeewxProxy.Mqtt do
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
      {Tortoise311.Connection,
       [
         name: WeewxProxy.Mqtt.WeewxBroker,
         client_id: Application.fetch_env!(:weewx_proxy, :mqtt_weewx_client_id),
         server:
           {Tortoise311.Transport.Tcp,
            host: Application.fetch_env!(:weewx_proxy, :mqtt_weewx_host),
            port: Application.fetch_env!(:weewx_proxy, :mqtt_weewx_port)},
         user_name: Application.fetch_env!(:weewx_proxy, :mqtt_weewx_user),
         password: Application.fetch_env!(:weewx_proxy, :mqtt_weewx_password),
         handler: {Tortoise311.Handler.Logger, []}
       ]},
      {Tortoise311.Connection,
       [
         name: WeewxProxy.Mqtt.SdrIngest,
         client_id: Application.fetch_env!(:weewx_proxy, :mqtt_sdr_client_id),
         server:
           {Tortoise311.Transport.Tcp,
            host: Application.fetch_env!(:weewx_proxy, :mqtt_sdr_host),
            port: Application.fetch_env!(:weewx_proxy, :mqtt_sdr_port)},
         user_name: Application.fetch_env!(:weewx_proxy, :mqtt_sdr_user),
         password: Application.fetch_env!(:weewx_proxy, :mqtt_sdr_password),
         subscriptions: ["rtl433"],
         handler: {WeewxProxy.Sdr.Ecowitt, []}
       ]}
    ]

    :sdr_ecowitt = :ets.new(:sdr_ecowitt, [:set, :public, :named_table, {:read_concurrency, true}])
    :purpleair = :ets.new(:purpleair, [:set, :public, :named_table, {:read_concurrency, true}])

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 9, max_seconds: 5)
  end
end
