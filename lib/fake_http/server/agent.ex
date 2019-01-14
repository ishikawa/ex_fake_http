defmodule FakeHTTP.Server.Agent do
  @moduledoc false
  use GenServer

  @type agent :: GenServer.server()

  @initial_state %{
    requests: :queue.new(),
    responses: :queue.new()
  }

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @spec enqueue_request(agent, Raxx.Request.t()) :: :ok
  def enqueue_request(agent, %Raxx.Request{} = request) do
    GenServer.call(agent, {:enqueue_request, request})
  end

  @spec enqueue_response(agent, Raxx.Response.t()) :: :ok
  def enqueue_response(agent, %Raxx.Response{} = response) do
    GenServer.call(agent, {:enqueue_response, response})
  end

  @spec dequeue_request(agent) :: {:ok, Raxx.Request.t()} | :error
  def dequeue_request(agent) do
    GenServer.call(agent, {:dequeue_request})
  end

  @spec dequeue_response(agent) :: {:ok, Raxx.Response.t()} | :error
  def dequeue_response(agent) do
    GenServer.call(agent, {:dequeue_response})
  end

  @spec reset(agent) :: :ok
  def reset(agent) do
    GenServer.call(agent, {:reset})
  end

  ## Callbacks

  @impl true
  def init(state) do
    state = Map.merge(@initial_state, state)

    {:ok, state}
  end

  @impl true
  def handle_call({:enqueue_request, request}, _from, %{requests: q} = state) do
    {:reply, :ok, %{state | requests: :queue.in(request, q)}}
  end

  @impl true
  def handle_call({:enqueue_response, response}, _from, %{responses: q} = state) do
    {:reply, :ok, %{state | responses: :queue.in(response, q)}}
  end

  @impl true
  def handle_call({:dequeue_request}, _from, %{requests: q} = state) do
    case :queue.out(q) do
      {:empty, _q} ->
        {:reply, :error, state}

      {{:value, request}, q2} ->
        {:reply, {:ok, request}, %{state | requests: q2}}
    end
  end

  @impl true
  def handle_call({:dequeue_response}, _from, %{responses: q} = state) do
    case :queue.out(q) do
      {:empty, _q} ->
        {:reply, :error, state}

      {{:value, response}, q2} ->
        {:reply, {:ok, response}, %{state | responses: q2}}
    end
  end

  @impl true
  def handle_call({:reset}, _from, _state) do
    {:reply, :ok, @initial_state}
  end
end
