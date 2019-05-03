defmodule FakeHTTP do
  @moduledoc false

  use Application

  def start(_type, _args) do
    warn_on_missing_json_library()

    children = [
      {FakeHTTP.Server.Registry, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Returns the configured JSON library.

  To customize the JSON library, include proper dependencies in your
  `mix.exs` and include the following in your `config/config.exs`:

      config :ex_fake_http, :json_library, Jason

  """
  def json_library do
    Application.get_env(:ex_fake_http, :json_library, Poison)
  end

  defp warn_on_missing_json_library do
    configured_lib = Application.get_env(:ex_fake_http, :json_library)
    default_lib = json_library()

    cond do
      configured_lib && not Code.ensure_loaded?(configured_lib) ->
        warn_json(configured_lib, """
        found #{inspect(configured_lib)} in your application configuration
        for FakeHTTP JSON encoding, but failed to load the library.
        """)

      not Code.ensure_loaded?(default_lib) and Code.ensure_loaded?(Jason) ->
        warn_json(Jason)

      not Code.ensure_loaded?(default_lib) ->
        warn_json(default_lib)

      true ->
        :ok
    end
  end

  defp warn_json(lib, preabmle \\ nil) do
    IO.warn("""
    #{preabmle || "failed to load #{inspect(lib)} for FakeHTTP JSON encoding"}
    (module #{inspect(lib)} is not available).

    Ensure #{inspect(lib)} exists in your deps in mix.exs,
    and you have configured FakeHTTP to use it for JSON encoding by
    verifying the following exists in your config/config.exs:

        config :ex_fake_http, :json_library, #{inspect(lib)}

    """)
  end
end
