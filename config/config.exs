import Config

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :logger,
  backends: [],
  level: :warning,
  handle_otp_reports: false,
  handle_sasl_reports: false
