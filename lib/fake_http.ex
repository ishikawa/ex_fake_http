defmodule FakeHTTP do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {FakeHTTP.Server.Registry, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
