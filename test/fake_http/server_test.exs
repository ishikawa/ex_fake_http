defmodule FakeHTTP.ServerTest do
  use ExUnit.Case, async: true

  alias FakeHTTP.Server

  setup do
    server = start_supervised!(Server)
    agent = Server.agent!(server)

    {:ok, %{server: server, agent: agent}}
  end

  describe "start_link" do
    test "given no option", %{server: server} do
      assert server
      assert Process.alive?(server)
    end

    test "given port number" do
      # Take an available port
      {:ok, socket} = :gen_tcp.listen(0, [:inet])
      {:ok, port} = :inet.port(socket)

      :ok = :gen_tcp.close(socket)

      # Start a server
      server = start_supervised!({Server, [port: port]})
      assert base_url = Server.base_url(server)
      assert base_url =~ ~r":#{port}"
    end
  end

  describe "stop" do
    test "stop a server started", %{server: server} do
      assert :ok == Server.stop(server)
      refute Process.alive?(server)
    end
  end

  describe "base_url" do
    test "returns base URL for server", %{server: server} do
      assert base_url = Server.base_url(server)
      assert base_url =~ ~r"^http://localhost:\d+$"
    end
  end

  describe "enqueue" do
    test "given status code and body", %{server: server, agent: agent} do
      assert :ok = Server.enqueue(server, 400, %{error: :bad_request})
      assert {:ok, response} = Server.Agent.dequeue_response(agent)
      assert response.status == 400
      assert :proplists.get_value("content-type", response.headers) == "application/json"
      assert FakeHTTP.json_library().decode!(response.body) == %{"error" => "bad_request"}
    end
  end
end
