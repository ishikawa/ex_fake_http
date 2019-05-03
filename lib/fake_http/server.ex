defmodule FakeHTTP.Server do
  @moduledoc """
  The main interface of a scriptable HTTP server
  """
  use Supervisor

  alias FakeHTTP.Server

  defstruct [:supervisor, :registry_name, :unique_key]

  ## Types

  @type server :: GenServer.server()

  @type options :: [GenServer.option()]

  @type on_start() ::
          {:ok, pid}
          | {:error, {:already_started, pid} | {:shutdown, term} | term}

  @type status_code :: integer | atom

  @type body :: map | binary

  @type headers :: [{binary, binary}] | %{binary => binary}

  def child_spec(init_arg) do
    # Because multiple server processes are required for the same test,
    # we override the default `id` with a reference.
    super(init_arg)
    |> Supervisor.child_spec(id: make_ref())
  end

  @doc """
  Starts a new `FakeHTTP.Server` process with the given `opts` options.

  ## Options

  - `port` - The port number of a HTTP server (default: `0`. It means the underlying OS will
             assign an available port number)
  - `name` - Register a started process (supervisor) with gicen `name`.
  """
  @spec start_link(options) :: on_start
  def start_link(opts \\ []) do
    unique_key = make_ref()

    {http_service_opts, sup_opts} = Keyword.split(opts, [:port])
    init_args = {%{unique_key: unique_key}, http_service_opts}
    sup_opts = Keyword.put(sup_opts, :strategy, :one_for_one)

    with {:ok, server} <- Supervisor.start_link(__MODULE__, init_args, sup_opts) do
      case Server.Registry.register_unique_key(server, unique_key) do
        {:ok, _owner} ->
          {:ok, server}

        {:error, {:already_registered, owner}} ->
          raise "The unique_key #{inspect(unique_key)} is already registered by the process #{
                  inspect(owner)
                }"
      end
    end
  end

  @doc """
  Shutdown the `server`.
  """
  @spec stop(server) :: :ok
  def stop(server) do
    Supervisor.stop(server)
  end

  @doc """
  Returns a corresponding agent name or raises error.
  """
  @spec agent!(server) :: GenServer.server() | no_return
  def agent!(server) do
    case Server.Registry.lookup_unique_key(server) do
      {:ok, unique_key} ->
        Server.Registry.agent_name(unique_key)

      _else ->
        raise "Couldn't get agent for server #{inspect(server)}"
    end
  end

  @doc """
  Resets the internal states in the `server`.
  """
  @spec reset(server) :: :ok
  def reset(server) do
    Server.Agent.reset(agent!(server))
  end

  @spec base_url(server) :: String.t() | no_return
  def base_url(server) do
    with {:ok, unique_key} <- Server.Registry.lookup_unique_key(server),
         http_service_name = Server.Registry.http_service_name(unique_key),
         {:ok, port} <- Ace.HTTP.Service.port(http_service_name) do
      "http://localhost:#{port}"
    else
      _ ->
        raise "Couldn't fetch the port number of HTTP server for #{inspect(server)}"
    end
  end

  @doc """
  Enqueue a new response which will return from the HTTP server.

  ## Examples

      Server.enqueue(server, 200)                            # 200 OK
      Server.enqueue(server, :forbidden)                     # 403 Forbidden
      Server.enqueue(server, %{"x" => 12345})                # application/json
      Server.enqueue(server, "hello, world!")                # text/plain
      Server.enqueue(server, 400, %{error: "bad_request"})   # 403 Forbidden + application/json

  """
  @spec enqueue(server, term) :: :ok | no_return
  def enqueue(server, raw_response) do
    case build_response(raw_response) do
      {:ok, response} ->
        Server.Agent.enqueue_response(agent!(server), response)

      {:error, reason} ->
        raise "Couldn't build response from #{inspect(raw_response)} (reason: #{inspect(reason)})"
    end
  end

  @spec enqueue(server, status_code, body) :: :ok | no_return
  def enqueue(server, status_code, body) do
    enqueue(server, {status_code, body})
  end

  @spec enqueue(server, status_code, body, headers) :: :ok | no_return
  def enqueue(server, status_code, body, headers) do
    enqueue(server, {status_code, body, headers})
  end

  @spec take(server) :: {:ok, FakeHTTP.Request.t()} | :error
  def take(server) do
    with {:ok, request} <- Server.Agent.dequeue_request(agent!(server)) do
      {:ok, FakeHTTP.Request.new(request)}
    end
  end

  # Callbacks

  @impl true
  def init({%{unique_key: unique_key} = args, http_service_opts}) do
    agent_name = Server.Registry.agent_name(unique_key)
    http_service_name = Server.Registry.http_service_name(unique_key)
    http_service_opts = Keyword.put(http_service_opts, :name, http_service_name)

    children = [
      {Server.Agent, name: agent_name},
      {Server.HTTPService, [args, http_service_opts]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  ## Private

  @spec build_response(Raxx.Response.t() | body | status_code | {status_code, body}) ::
          {:ok, Raxx.Response.t()} | {:error, reason :: term}
  defp build_response(%Raxx.Response{} = response) do
    {:ok, response}
  end

  defp build_response(status_code) when is_integer(status_code) or is_atom(status_code) do
    build_response({status_code, ""})
  end

  defp build_response(body) when not is_tuple(body) do
    build_response({:ok, body})
  end

  defp build_response({status_code, body}) do
    build_response({status_code, body, []})
  end

  defp build_response({status_code, body, headers}) do
    Raxx.response(status_code)
    |> add_headers(headers)
    |> set_body(body)
    |> case do
      {:error, _reason} = e -> e
      response -> build_response(response)
    end
  end

  defp add_headers(response, headers) do
    headers
    |> Enum.reduce(response, fn {k, v}, response ->
      Raxx.set_header(response, to_string(k), v)
    end)
  end

  defp set_body(response, json_map) when is_map(json_map) do
    with {:ok, body} <- FakeHTTP.json_library().encode(json_map) do
      set_default_content_type(response, "application/json")
      |> Raxx.set_body(body)
    end
  end

  defp set_body(response, body) when is_binary(body) do
    set_default_content_type(response, "text/plain")
    |> Raxx.set_body(body)
  end

  defp set_default_content_type(response, content_type) do
    unless Raxx.get_header(response, "content-type") do
      Raxx.set_header(response, "content-type", content_type)
    else
      response
    end
  end
end
