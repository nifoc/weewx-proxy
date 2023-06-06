import Config

config :weewx_proxy,
  mqtt_weewx_host: elem(:inet.parse_address(to_charlist(System.fetch_env!("WEEWX_PROXY_MQTT_WEEWX_HOST"))), 1),
  mqtt_weewx_port: elem(Integer.parse(System.get_env("WEEWX_PROXY_MQTT_WEEWX_PORT", "1883")), 0),
  mqtt_weewx_user: System.fetch_env!("WEEWX_PROXY_MQTT_WEEWX_USER"),
  mqtt_weewx_password: System.fetch_env!("WEEWX_PROXY_MQTT_WEEWX_PASSWORD"),
  mqtt_weewx_client_id: String.to_atom("Elixir." <> System.get_env("WEEWX_PROXY_MQTT_WEEWX_CLIENT_ID", "WeewxBroker")),
  mqtt_sdr_host: elem(:inet.parse_address(to_charlist(System.fetch_env!("WEEWX_PROXY_MQTT_SDR_HOST"))), 1),
  mqtt_sdr_port: elem(Integer.parse(System.get_env("WEEWX_PROXY_MQTT_SDR_PORT", "1883")), 0),
  mqtt_sdr_user: System.fetch_env!("WEEWX_PROXY_MQTT_SDR_USER"),
  mqtt_sdr_password: System.fetch_env!("WEEWX_PROXY_MQTT_SDR_PASSWORD"),
  mqtt_sdr_client_id: String.to_atom("Elixir." <> System.get_env("WEEWX_PROXY_MQTT_SDR_CLIENT_ID", "SdrIngestLocal")),
  purpleair_url: System.fetch_env!("WEEWX_PROXY_PURPLEAIR_URL")
