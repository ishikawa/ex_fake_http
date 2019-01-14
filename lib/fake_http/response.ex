defmodule FakeHTTP.Response do
  @moduledoc """
  This module represents a HTTP response.
  """
  defstruct status_code: 200, headers: [], body: ""

  alias FakeHTTP.Request

  @type t :: %__MODULE__{body: Request.body(), headers: Request.headers(), status_code: integer}
end
