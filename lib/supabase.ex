defmodule Supabase do
  @moduledoc """
  Elixir library for `Supabase`.
  """

  def auth(), do: GoTrue

  @doc """
  Entrypoint for implementing the same API the JS library does.
  """
  def storage() do
    raise "This version of the storage API is not implemented yet"
  end
end
