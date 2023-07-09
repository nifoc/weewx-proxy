defmodule WeewxProxy.Sdr.Ecowitt do
  @moduledoc false

  require Logger

  use Tortoise311.Handler

  alias WeewxProxy.HTTP.PurpleAir
  alias WeewxProxy.{Publisher, Utils}

  @type parsed_body :: %{required(String.t()) => String.t() | float() | integer()}

  # API

  @spec recently_uploaded_keys :: [atom()]
  def recently_uploaded_keys do
    current_timestamp = Utils.utc_timestamp()
    recently_uploaded_keys(current_timestamp)
  end

  @spec recently_uploaded_keys(non_neg_integer()) :: [atom()]
  def recently_uploaded_keys(current_timestamp) do
    wh65b_keys =
      case :ets.lookup(:sdr_ecowitt, {:wh65b, :last_update}) do
        [{_key, timestamp}] when current_timestamp - timestamp < 48 ->
          [:outTemp, :outHumidity, :windSpeed, :windGust, :windDir]

        _ ->
          []
      end

    wh32b_keys =
      case :ets.lookup(:sdr_ecowitt, {:wh32b, :last_update}) do
        [{_key, timestamp}] when current_timestamp - timestamp < 80 ->
          [:inTemp, :inHumidity, :pressure]

        _ ->
          []
      end

    wh65b_keys ++ wh32b_keys
  end

  # Callbacks

  @impl true
  def init(_opts) do
    _ = Logger.info("Initializing handler")
    {:ok, nil}
  end

  @impl true
  def connection(:up, state) do
    _ = Logger.info("Connection has been established")
    {:ok, state}
  end

  @impl true
  def connection(:down, state) do
    _ = Logger.warning("Connection has been dropped")
    {:ok, state}
  end

  @impl true
  def connection(:terminating, state) do
    _ = Logger.warning("Connection is terminating")
    {:ok, state}
  end

  @impl true
  def subscription(:up, topic, state) do
    _ = Logger.info("Subscribed to `#{topic}'")
    {:ok, state}
  end

  @impl true
  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    _ = Logger.warning("Subscribed to `#{topic}'; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  @impl true
  def subscription({:error, reason}, topic, state) do
    _ = Logger.error("Error subscribing to `#{topic}'; #{inspect(reason)}")
    {:ok, state}
  end

  @impl true
  def subscription(:down, topic, state) do
    _ = Logger.info("Unsubscribed from `#{topic}'")
    {:ok, state}
  end

  @impl true
  def handle_message(topic, publish, state) do
    full_topic = Enum.join(topic, "/")
    parsed_message = parse_message(full_topic, publish)

    :ok = handle_reading(parsed_message)

    {:ok, state}
  end

  @impl true
  def terminate(reason, _state) do
    _ = Logger.warning("Client has been terminated with reason: `#{inspect(reason)}'")
    :ok
  end

  # Helper

  @spec parse_message(String.t(), String.t()) :: parsed_body() | nil
  defp parse_message("rtl433", message) do
    {:ok, body} = Jason.decode(message)

    if handle_reading?(body) do
      body
    else
      _ = Logger.warning("Ignoring reading: #{inspect(body)}")
      nil
    end
  end

  defp parse_message(_topic, _message), do: nil

  @spec handle_reading?(parsed_body()) :: boolean()
  defp handle_reading?(%{"model" => "Fineoffset-WH65B", "id" => 189}), do: true
  defp handle_reading?(%{"model" => "Fineoffset-WH32B", "id" => 173}), do: true
  defp handle_reading?(_reading), do: false

  @spec handle_reading(parsed_body() | nil) :: :ok
  defp handle_reading(nil), do: :ok

  defp handle_reading(body) do
    {type, data} = transform_data(body)

    :ok =
      if valid_data?(type, data) do
        purpleair_keys = PurpleAir.recently_uploaded_keys(data.dateTime)
        _ = Logger.debug("Removing keys: `#{inspect(purpleair_keys)}'")
        partial_data = Map.drop(data, purpleair_keys)

        true = :ets.insert(:sdr_ecowitt, {{type, :last_update}, data.dateTime})
        Publisher.publish("weewx/ingest_si", partial_data)
      else
        _ = Logger.error("Not publishing record because data appears invalid: #{inspect(data)}")
        :ok
      end

    :ok
  end

  @spec transform_data(parsed_body()) :: {:wh65b | :wh32b, Publisher.data()}
  defp transform_data(%{"model" => "Fineoffset-WH65B"} = data) do
    data = %{
      dateTime: format_date_time(data),
      outTemp: Utils.parse_float(data["temperature_C"]),
      outHumidity: Utils.parse_float(data["humidity"]),
      windSpeed: Utils.parse_float(data["wind_avg_m_s"]),
      windGust: Utils.parse_float(data["wind_max_m_s"]),
      windDir: Utils.parse_float(data["wind_dir_deg"]),
      luminosity: Utils.parse_float(data["light_lux"])
    }

    {:wh65b, data}
  end

  defp transform_data(%{"model" => "Fineoffset-WH32B"} = data) do
    data = %{
      dateTime: format_date_time(data),
      inTemp: Utils.parse_float(data["temperature_C"]),
      inHumidity: Utils.parse_float(data["humidity"]),
      pressure: Utils.parse_float(data["pressure_hPa"])
    }

    {:wh32b, data}
  end

  @spec format_date_time(parsed_body()) :: non_neg_integer()
  defp format_date_time(data) do
    {:ok, dt, 0} =
      data
      |> Map.get("time")
      |> String.replace(" ", "T")
      |> Utils.append_string("Z")
      |> DateTime.from_iso8601()

    DateTime.to_unix(dt)
  end

  @spec valid_data?(:wh65b | :wh32b, Publisher.data()) :: boolean()
  defp valid_data?(:wh65b, data) do
    Map.has_key?(data, :outTemp) and is_number(data.outTemp)
  end

  defp valid_data?(:wh32b, data) do
    Map.has_key?(data, :inTemp) and is_number(data.inTemp)
  end
end
