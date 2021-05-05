defmodule SupabaseTest do
  use ExUnit.Case

  import Supabase
  import Postgrestex

  test "postgrest integration" do
    response =
      Supabase.init()
      |> from("profiles")
      |> eq("username", "Patrick")
      |> call()
      |> json()

    assert response.status == 200
    assert length(response.body) == 1
  end
end
