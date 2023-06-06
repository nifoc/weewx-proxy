defmodule WeewxProxy.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    _ =
      case :logger.add_handlers(:systemd) do
        :ok ->
          :logger.remove_handler(:default)

        _ ->
          :logger.add_handler_filter(:default, :elixir_filter, {&:logger_filters.domain/2, {:log, :sub, [:elixir]}})
      end

    children = [
      WeewxProxy.Mqtt,
      WeewxProxy.Publisher,
      WeewxProxy.Http,
      :systemd.ready()
    ]

    opts = [strategy: :one_for_one, name: WeewxProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
