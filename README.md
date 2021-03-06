# FakeHTTP

[![CircleCI](https://circleci.com/gh/ishikawa/ex_fake_http.svg?style=shield)](https://circleci.com/gh/ishikawa/ex_fake_http)
[![Hex pm](http://img.shields.io/hexpm/v/ex_fake_http.svg?style=flat)](https://hex.pm/packages/ex_fake_http)

This library provides a scriptable HTTP server for testing HTTP based service (e.g. REST API). It makes easy to set up the server's resposens and test your code sends expected HTTP requests.

## Install

To use FakeHTTP in your Mix projects, first add FakeHTTP as a dependency.

```elixir
def deps do
  [
    {:ex_fake_http, "~> 0.3.0", only: :test}
  ]
end
```

After adding FakeHTTP as a dependency, run `mix deps.get` to install it.

## Usage

The only public module in this library is `FakeHTTP.Server` module.

`FakeHTTP.Server` implements full-fledged HTTP server. It establishes a real TCP
connection between it and a client. You can use it the same way that you use
other mocking libraries:

1. Start a process of server.
2. Script the mock responses.
3. Run your code.
4. Verify that the expected requests were made.

```elixir
defmodule YourApp.YourModuleTest do
  # Each test has its `FakeHTTP.Server` instance.
  # So it can be configured with `async` option enabled.
  use ExUnit.Case, async: true

  alias YourApp.ChatService

  setup_all do
    # Launch a HTTP server and internal Erlang process to
    # manage HTTP server.
    server = start_supervised!(FakeHTTP.Server)
    base_url = FakeHTTP.Server.base_url(server)

    {:ok, %{server: server, base_url: base_url}}
  end

  setup %{server: server} do
    # Reset internal states before each test started.
    FakeHTTP.Server.reset(server)
    :ok
  end

  test "GET from REST API", %{server: server, base_url: base_url} do
    path = "/messages/1"
    auth_header = "Basic dGVzdDp0ZXN0"

    # Register an expected response which the server should return for
    # the next request from a client.
    FakeHTTP.Server.enqueue(server, %{message: "hello"})

    # The started server is a real HTTP server. You can use your favorite
    # HTTP library to make a HTTP request without monkey-patched mocking.
    assert {:ok, response} = HTTPoison.get(base_url <> path, %{"Authorization" => auth_header})

    assert response.status_code == 200
    assert :proplists.get_value("content-type", response.headers) == "application/json"
    assert Jason.decode!(response.body) == %{"message" => "hello"}

    # Verify that the expected requests were made.
    {:ok, req} = FakeHTTP.Server.take(server)

    # Notice the `req` is an instance of `FakeHTTP.Request`.
    assert req.method == :get
    assert req.request_path == path
    assert req.headers["authorization"] == auth_header
  end
end
```

## License

MIT
