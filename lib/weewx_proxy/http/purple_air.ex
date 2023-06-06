defmodule WeewxProxy.HTTP.PurpleAir do
  require Logger

  use GenServer

  alias WeewxProxy.{Publisher, Utils}

  @type parsed_body :: %{required(String.t()) => String.t() | float() | integer()}

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

  # API

  @spec recently_uploaded_keys :: [atom()]
  def recently_uploaded_keys do
    current_timestamp = Utils.utc_timestamp()
    recently_uploaded_keys(current_timestamp)
  end

  @spec recently_uploaded_keys(non_neg_integer()) :: [atom()]
  def recently_uploaded_keys(current_timestamp) do
    case :ets.lookup(:purpleair, :last_update) do
      [{_key, timestamp}] when current_timestamp - timestamp < 70 ->
        [:pressure]

      _ ->
        []
    end
  end

  # Callbacks

  @impl true
  def init([]) do
    {:ok, %State{}, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, state) do
    :ok = Process.send(self(), :fetch, [])
    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch, state) do
    data = fetch_data()
    :ok = handle_reading(data)

    _ = trigger_fetch()
    {:noreply, %State{state | last_update: Utils.utc_timestamp()}}
  end

  @impl true
  def handle_info(request, state) do
    _ = Logger.error("Unexpected message: #{inspect(request)}")
    {:noreply, state}
  end

  # Helper

  @spec trigger_fetch :: reference()
  defp trigger_fetch do
    Process.send_after(self(), :fetch, 25_000)
  end

  @spec fetch_data :: parsed_body() | nil
  defp fetch_data do
    url = Application.fetch_env!(:weewx_proxy, :purpleair_url)

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, data} = Jason.decode(body)

        if handle_reading?(data) do
          data
        else
          _ = Logger.warn("Ignoring reading: #{inspect(data)}")
          nil
        end

      {:ok, response} ->
        _ = Logger.warn("Unexpected response: #{inspect(response)}")
        nil

      {:error, error} ->
        _ = Logger.error("Unexpected error: #{inspect(error)}")
        nil
    end
  end

  @spec handle_reading?(parsed_body()) :: boolean
  defp handle_reading?(data) do
    is_number(data["pm1_0_atm"]) and is_number(data["pm2_5_atm"]) and is_number(data["pm10_0_atm"]) and
      is_number(data["pm1_0_atm_b"]) and is_number(data["pm2_5_atm_b"]) and is_number(data["pm10_0_atm_b"]) and
      abs(data["pm2_5_atm"] - data["pm2_5_atm_b"]) < 200 and
      is_number(data["pressure"]) and is_number(data["pressure_680"]) and
      is_integer(data["uptime"]) and data["uptime"] > 120
  end

  @spec handle_reading(parsed_body() | nil) :: :ok
  defp handle_reading(nil), do: :ok

  defp handle_reading(data) do
    transformed_data = %{
      dateTime: format_date_time(data),
      pm1_0: calculate_mean(data, "pm1_0_atm", "pm1_0_atm_b"),
      pm2_5: calculate_mean(data, "pm2_5_atm", "pm2_5_atm_b"),
      pm10_0: calculate_mean(data, "pm10_0_atm", "pm10_0_atm_b"),
      pressure: calculate_mean(data, "pressure", "pressure_680")
    }

    _ = :ets.insert(:purpleair, {:last_update, transformed_data.dateTime})
    Publisher.publish("weewx/ingest_si", transformed_data)
  end

  @spec format_date_time(parsed_body()) :: non_neg_integer()
  defp format_date_time(data) do
    {:ok, dt, 0} =
      data |> Map.get("DateTime") |> String.replace("/", "-") |> String.upcase(:ascii) |> DateTime.from_iso8601()

    DateTime.to_unix(dt)
  end

  @spec calculate_mean(parsed_body(), String.t(), String.t()) :: float()
  defp calculate_mean(data, key_a, key_b) do
    data_a = data[key_a]
    data_b = data[key_b]

    raw_value =
      case {data_a, data_b} do
        {0.0, 0.0} -> 0.0
        {_, 0.0} -> data_a
        {0.0, _} -> data_b
        {_, _} -> (data_a + data_b) / 2.0
      end

    Float.round(raw_value, 4)
  end
end
