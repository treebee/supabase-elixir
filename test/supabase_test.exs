defmodule SupabaseTest do
  use ExUnit.Case

  import Supabase
  import Postgrestex

  test "postgrest integration" do
    response =
      Supabase.init()
      |> from("profiles")
      |> call()
      |> json()

    assert response.status == 200
    assert is_list(response.body)
  end
end
