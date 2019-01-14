defmodule FakeHTTP.Request do
  @moduledoc """
  This module represents a HTTP request.

  `Request` properties:

  * `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`, `:delete`, etc.)
  * `request_path` - the requested path, example: `/path/to/index.html`
  * `headers` - the request headers as a map
  * `body` - the request body
  """
  defstruct method: :get, request_path: "/", headers: %{}, body: ""

  @type method :: :get | :post | :put | :patch | :delete | :options | :head

  @type headers :: %{binary => binary}

  @type body :: term

  @type t :: %__MODULE__{method: method, request_path: binary, headers: headers, body: body}

  @raxx_methods %{
    :GET => :get,
    :POST => :post,
    :PUT => :put,
    :PATCH => :patch,
    :DELETE => :delete,
    :OPTIONS => :options,
    :HEAD => :head
  }

  @doc false
  @spec new(Raxx.Request.t()) :: t
  def new(%Raxx.Request{} = request) do
    %__MODULE__{
      method: Map.fetch!(@raxx_methods, request.method),
      request_path: Raxx.normalized_path(request),
      headers: Map.new(request.headers),
      body: request.body
    }
  end
end
