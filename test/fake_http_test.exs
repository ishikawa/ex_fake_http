defmodule FakeHTTPTest do
  use ExUnit.Case, async: true

  setup_all do
    server = start_supervised!(FakeHTTP.Server)
    base_url = FakeHTTP.Server.base_url(server)

    {:ok, %{server: server, base_url: base_url}}
  end

  setup %{server: server} do
    FakeHTTP.Server.reset(server)
    :ok
  end

  describe "server" do
    test "simple JSON", %{server: server, base_url: base_url} do
      path = "/messages/1"
      auth_header = "Basic dGVzdDp0ZXN0"

      FakeHTTP.Server.enqueue(server, %{message: "hello"})

      assert {:ok, response} = HTTPoison.get(base_url <> path, %{"Authorization" => auth_header})

      assert response.status_code == 200
      assert :proplists.get_value("content-type", response.headers) == "application/json"
      assert FakeHTTP.json_library().decode!(response.body) == %{"message" => "hello"}

      # Verify that the expected requests were made.
      {:ok, req} = FakeHTTP.Server.take(server)

      assert req.method == :get
      assert req.request_path == path
      assert req.headers["authorization"] == auth_header
    end

    test "scheme, authority", %{server: server, base_url: base_url} do
      FakeHTTP.Server.enqueue(server, %{message: "hello"})
      assert {:ok, _response} = HTTPoison.get("#{base_url}/hello")

      {:ok, req} = FakeHTTP.Server.take(server)

      assert req.scheme == :http
      assert "#{req.scheme}://#{req.host}:#{req.port}" == base_url
    end

    test "given status_code integer value", %{server: server, base_url: base_url} do
      FakeHTTP.Server.enqueue(server, 200)
      assert {:ok, response} = HTTPoison.get(base_url)
      assert response.status_code == 200
      headers = Map.new(response.headers)
      assert headers["content-type"] == "text/plain"
      assert headers["content-length"] == "0"
    end

    test "given status_code name", %{server: server, base_url: base_url} do
      FakeHTTP.Server.enqueue(server, :forbidden)
      assert {:ok, response} = HTTPoison.get(base_url)
      assert response.status_code == 403
      headers = Map.new(response.headers)
      assert headers["content-type"] == "text/plain"
      assert headers["content-length"] == "0"
    end
  end
end
