defmodule WeewxProxy.Publisher do
  require Logger

  use GenServer

  alias WeewxProxy.Utils

  @type data :: %{required(atom) => number() | nil}

  defmodule State do
    # credo:disable-for-previous-line Credo.Check.Readability.ModuleDoc

    use TypedStruct

    typedstruct do
      field :last_update, non_neg_integer(), default: 0
    end
  end

  @name __MODULE__

  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  @spec start_link :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @spec publish(String.t(), data()) :: :ok
  def publish(topic, data) do
    filtered_data = :maps.filter(fn _k, v -> not is_nil(v) end, data)
    GenServer.cast(@name, {:publish, topic, filtered_data})
  end

  # Callbacks

  @impl true
  def init([]) do
    {:ok, %State{}}
  end

  @impl true
  def handle_cast({:publish, topic, data}, state) do
    {:ok, json_data} = Jason.encode(data)
    _ = Logger.info("Publishing record to #{topic}")
    _ = Tortoise311.publish(WeewxBroker, topic, json_data, qos: 0, timeout: 5000)
    _ = Logger.debug("Published record: #{inspect(data)}")

    {:noreply, %State{state | last_update: Utils.utc_timestamp()}}
  end
end
