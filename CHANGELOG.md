# Changelog

## 0.3.0

Switched the default JSON library to [Poison](https://github.com/devinus/poison) from [Jason](https://github.com/michalmuskala/jason) because Poison's support for encoding arbitrary structs is useful for testing. If you want to use Jason as JSON library in FakeHTTP, you can configure it in your config/config.exs:

```elixir
config :ex_fake_http, :json_library, Jason
```

## 0.2.0

From this version, you can configure the port number of a HTTP server.

```elixir
{:ok, server} = FakeHTTP.Server.start_link(port: 5432)
```

So you can configure your HTTP access module with the pre-defined port number **before** the tests started.
