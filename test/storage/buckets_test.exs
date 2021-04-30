defmodule Supabase.Storage.BucketsTest do
  use ExUnit.Case

  alias Supabase.Storage.Bucket
  alias Supabase.Storage.Buckets

  @bucket_name "testbucket"

  setup_all context do
    conn =
      Supabase.Connection.new(
        System.get_env("SUPABASE_TEST_URL"),
        System.get_env("SUPABASE_TEST_KEY")
      )

    {:ok, %{"name" => @bucket_name}} = Buckets.create(conn, @bucket_name)
    # always clean up our test bucket
    on_exit(fn ->
      Buckets.delete(conn, @bucket_name)
    end)

    Map.put(context, :conn, conn)
  end

  test "list buckets", %{conn: conn} do
    {:ok, buckets} = Buckets.list(conn)
    assert length(buckets) == 1
    [bucket] = buckets
    assert bucket.id == @bucket_name
  end

  test "get bucket", %{conn: conn} do
    {:ok, %Bucket{} = bucket} = Buckets.get(conn, @bucket_name)
    assert bucket.id == @bucket_name
  end
end
