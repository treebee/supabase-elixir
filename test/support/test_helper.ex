defmodule Supabase.TestHelper do
  def connection() do
    Supabase.Connection.new(
      Application.fetch_env!(:supabase, :base_url),
      Application.fetch_env!(:supabase, :api_key)
    )
  end
end
