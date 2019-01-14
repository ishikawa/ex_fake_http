defmodule FakeHTTP.Server.HTTPService do
  @moduledoc false

  use Ace.HTTP.Service, port: 0, cleartext: true
  use Raxx.SimpleServer

  alias FakeHTTP.Server

  @impl Raxx.SimpleServer
  def handle_request(request, %{unique_key: unique_key}) do
    agent = Server.Registry.agent_name(unique_key)

    with :ok <- Server.Agent.enqueue_request(agent, request),
         {:ok, response} <- Server.Agent.dequeue_response(agent) do
      response
    else
      :error ->
        raise "Nothing remains in response queue"
    end
  end
end
