defmodule SupabaseTest do
  use ExUnit.Case

  import Supabase
  import Postgrestex

  test "postgrest integration" do
    Application.put_env(:supabase, :base_url, System.get_env("SUPABASE_TEST_URL"))
    Application.put_env(:supabase, :api_key, System.get_env("SUPABASE_TEST_KEY"))
    # Supabase.init(System.get_env("SUPABASE_TEST_URL"), System.get_env("SUPABASE_TEST_KEY"))
    response =
      Supabase.rest()
      |> from("profiles")
      |> json()

    assert response.status == 200
    assert is_list(response.body)
  end
end
