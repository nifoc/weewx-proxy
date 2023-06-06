defmodule WeewxProxy.HTTP.Ecowitt do
  require Logger

  use Plug.Router

  alias WeewxProxy.{Publisher, Utils}
  alias WeewxProxy.Sdr.Ecowitt, as: Sdr

  @type parsed_body :: %{required(String.t()) => String.t()}

  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  post "/update" do
    body = conn.body_params
    _ = Logger.debug("Incoming request body: #{inspect(body)}")
    data = transform_data(body)

    :ok =
      if valid_data?(data) do
        sdr_keys = Sdr.recently_uploaded_keys(data.dateTime)
        _ = Logger.debug("Removing keys: `#{inspect(sdr_keys)}'")
        partial_data = Map.drop(data, sdr_keys)
        Publisher.publish("weewx/ingest_us", partial_data)
      else
        _ = Logger.error("Not publishing record because data appears invalid: #{inspect(data)}")
        :ok
      end

    tz = System.get_env("TZ", "Europe/Berlin")
    utc_offset = Utils.utc_offset_string(tz)
    response = ~s({"errcode":"0","errmsg":"ok","UTC_offset":"#{utc_offset}"})

    send_resp(conn, 200, response)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  # Private

  @spec transform_data(parsed_body()) :: Publisher.data()
  defp transform_data(data) do
    # Fields with totals:
    # - rain
    # - lightning_strike_count

    %{
      dateTime: format_date_time(data),
      # Outdoor
      outTemp: Utils.parse_float(data["tempf"]),
      outHumidity: Utils.parse_float(data["humidity"]),
      pressure: Utils.parse_float(data["baromabsin"]),
      windSpeed: Utils.parse_float(data["windspeedmph"]),
      windGust: Utils.parse_float(data["windgustmph"]),
      windDir: Utils.parse_float(data["winddir"]),
      rain: Utils.parse_float(data["yearlyrainin"]),
      rainRate: Utils.parse_float(data["rainratein"]),
      UV: Utils.parse_float(data["uv"]),
      radiation: Utils.parse_float(data["solarradiation"]),
      soilMoist1: Utils.parse_float(data["soilmoisture1"]),
      soilTemp1: Utils.parse_float(data["tf_ch1"]),
      lightning_strike_count: calculate_lightning_strike_count(data),
      lightning_last_det_time: Utils.parse_integer(data["lightning_time"]),
      lightning_distance: calculate_lightning_distance(data),
      # Indoor
      inTemp: Utils.parse_float(data["tempinf"]),
      inHumidity: Utils.parse_float(data["humidityin"]),
      # Battery
      soilMoistBatteryVoltage1: Utils.parse_float(data["soilbatt1"]),
      soilTempBatteryVoltage1: Utils.parse_float(data["tf_batt1"])
    }
  end

  @spec format_date_time(parsed_body()) :: non_neg_integer()
  defp format_date_time(data) do
    {:ok, dt, 0} =
      data |> Map.get("dateutc") |> String.replace("+", "T") |> Utils.append_string("Z") |> DateTime.from_iso8601()

    DateTime.to_unix(dt)
  end

  @spec calculate_lightning_strike_count(parsed_body()) :: float() | nil
  defp calculate_lightning_strike_count(data) do
    if Map.has_key?(data, "lightning_num") do
      value = Utils.parse_float(data["lightning_num"])
      if is_nil(value), do: 0.0, else: value
    else
      nil
    end
  end

  @spec calculate_lightning_distance(parsed_body()) :: float() | nil
  defp calculate_lightning_distance(data) do
    distance_km = data["lightning"]
    strikes = calculate_lightning_strike_count(data)

    current_time = Utils.utc_timestamp()
    lightning_time = Utils.parse_integer(data["lightning_time"])
    time_diff = current_time - lightning_time

    if is_binary(distance_km) and is_number(strikes) and byte_size(distance_km) > 0 and strikes > 0 and time_diff < 1200 do
      0.62137119 * Utils.parse_float(distance_km)
    else
      nil
    end
  end

  @spec valid_data?(Publisher.data()) :: boolean()
  defp valid_data?(data) do
    Map.has_key?(data, :outTemp) and is_number(data.outTemp)
  end
end
