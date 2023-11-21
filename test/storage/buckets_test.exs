defmodule Supabase.Storage.BucketsTest do
  use ExUnit.Case

  alias Supabase.Storage

  @bucket_name "testbucket"

  setup_all context do
    conn = Supabase.TestHelper.connection()

    {:ok, %{"name" => @bucket_name}} = Storage.create_bucket(conn, @bucket_name)
    # always clean up our test bucket
    on_exit(fn ->
      Storage.delete_bucket(conn, @bucket_name)
    end)

    Map.put(context, :conn, conn)
  end

  test "list buckets", %{conn: conn} do
    buckets = Storage.list_buckets!(conn)
    assert length(buckets) == 1
    [bucket] = buckets
    assert bucket.id == @bucket_name
  end

  test "get bucket", %{conn: conn} do
    bucket = Storage.get_bucket!(conn, @bucket_name)
    assert bucket.id == @bucket_name
  end
end
