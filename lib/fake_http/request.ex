defmodule FakeHTTP.Request do
  @moduledoc """
  This module represents a HTTP request.

  `Request` properties:

  * `host` - the requested host as a binary, example: `"www.example.com"`
  * `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`, `:delete`, etc.)
  * `scheme` - the request scheme as an atom, example: `:http`
  * `port` - the requested port as an integer, example: `80`
  * `request_path` - the requested path, example: `/path/to/index.html`
  * `headers` - the request headers as a map
  * `body` - the request body
  """
  defstruct scheme: :http,
            method: :get,
            host: "www.example.com",
            port: 80,
            request_path: "/",
            headers: %{},
            body: ""

  @type scheme :: atom

  @type method :: :get | :post | :put | :patch | :delete | :options | :head

  @type headers :: %{binary => binary}

  @type body :: term

  @type t :: %__MODULE__{
          scheme: scheme,
          method: method,
          host: binary,
          port: integer,
          request_path: binary,
          headers: headers,
          body: body
        }

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
      scheme: request.scheme,
      method: Map.fetch!(@raxx_methods, request.method),
      host: Raxx.Request.host(request),
      port: Raxx.Request.port(request),
      request_path: Raxx.normalized_path(request),
      headers: Map.new(request.headers),
      body: request.body
    }
  end
end
