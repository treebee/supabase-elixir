defmodule SupabaseTest do
  use ExUnit.Case

  import Supabase
  import Postgrestex

  test "postgrest integration" do
    response =
      Supabase.init(System.get_env("SUPABASE_TEST_URL"), System.get_env("SUPABASE_TEST_KEY"))
      |> from("profiles")
      |> call()
      |> json()

    assert response.status == 200
    assert is_list(response.body)
  end
end
