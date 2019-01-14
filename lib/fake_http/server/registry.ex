defmodule FakeHTTP.Server.Registry do
  @moduledoc false

  @doc """
  Returns the name of the shared registry.
  """
  @default_name __MODULE__
  @spec name :: GenServer.name()
  def name, do: @default_name

  @spec agent_name(term, Keyword.t()) :: GenServer.name()
  def agent_name(unique_key, opts \\ []), do: build_name(FakeHTTP.Server.Agent, unique_key, opts)

  @spec http_service_name(term, Keyword.t()) :: GenServer.name()
  def http_service_name(unique_key, opts \\ []),
    do: build_name(FakeHTTP.Server.HTTPService, unique_key, opts)

  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, term}
  def start_link(opts) do
    opts = Keyword.merge(opts, keys: :unique, name: @default_name)
    Registry.start_link(opts)
  end

  @doc """
  Returns a specification to start a registry under a supervisor.
  """
  def child_spec(opts) do
    Registry.child_spec(opts)
    |> Map.put(:start, {__MODULE__, :start_link, [opts]})
  end

  @spec register_unique_key(FakeHTTP.Server.server(), term) ::
          {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register_unique_key(server, unique_key) do
    pid = ensure_server_pid(server)
    Registry.register(@default_name, {pid, :unique_key}, unique_key)
  end

  @spec lookup_unique_key(FakeHTTP.Server.server()) :: {:ok, term} | :error
  def lookup_unique_key(server) do
    pid = ensure_server_pid(server)

    case Registry.lookup(@default_name, {pid, :unique_key}) do
      [] -> :error
      [{_owner, unique_key}] -> {:ok, unique_key}
    end
  end

  ## Private

  @spec build_name(module, term, Keyword.t()) :: GenServer.name()
  defp build_name(mod, unique_key, opts) do
    registry_name = Keyword.get(opts, :registry_name, @default_name)
    {:via, Registry, {registry_name, {mod, unique_key}}}
  end

  @spec ensure_server_pid(FakeHTTP.Server.server()) :: pid | nil
  defp ensure_server_pid(server) when is_pid(server), do: server
  defp ensure_server_pid(server), do: Process.whereis(server)
end
