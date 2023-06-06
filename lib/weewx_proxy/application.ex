defmodule WeewxProxy.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
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
