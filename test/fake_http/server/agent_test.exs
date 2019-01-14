defmodule FakeHTTP.Server.AgentTest do
  use ExUnit.Case, async: true

  alias FakeHTTP.Server

  setup do
    agent = start_supervised!(Server.Agent)

    {:ok, %{agent: agent}}
  end

  describe "start_link" do
    test "given no option", %{agent: agent} do
      assert agent
      assert Process.alive?(agent)
    end
  end

  describe "enqueue_response and dequeue_response" do
    test "given response", %{agent: agent} do
      res = Raxx.response(:ok)
      assert :ok == Server.Agent.enqueue_response(agent, res)
      assert {:ok, res} = Server.Agent.dequeue_response(agent)
    end
  end
end
