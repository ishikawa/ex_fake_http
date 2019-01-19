# Changelog

## 0.2

From this version, you can configure the port number of a HTTP server.

```elixir
{:ok, server} = FakeHTTP.Server.start_link(port: 5432)
```

So you can configure your HTTP access module with the pre-defined port number **before** the tests started.
