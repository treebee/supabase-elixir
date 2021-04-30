defmodule Supabase.Storage.ObjectsTest do
  # use Supabase.ConnectionCase
  use ExUnit.Case

  alias Supabase.Storage.Buckets
  alias Supabase.Storage.Objects

  @bucket_name "testbucket"
  @file_path "test/data/galen-crout-8skNUw3Z1FA-unsplash.jpg"
  @object_path "images/unsplash.jpg"

  defp create_object(conn) do
    {:ok, %{"Key" => object_path}} = Objects.create(conn, @bucket_name, @object_path, @file_path)
    object_path
  end

  setup_all context do
    conn =
      Supabase.Connection.new(
        System.get_env("SUPABASE_TEST_URL"),
        System.get_env("SUPABASE_TEST_KEY")
      )

    {:ok, %{"name" => @bucket_name}} =
      case Buckets.create(conn, @bucket_name) do
        {:error, %{"error" => "Key (id)=(testbucket) already exists."}} ->
          Buckets.delete_cascase(conn, @bucket_name)
          Buckets.create(conn, @bucket_name)

        response ->
          response
      end

    {:ok, bucket} = Buckets.get(conn, @bucket_name)
    object_path = create_object(conn)

    # always clean up our test bucket
    on_exit(fn ->
      Buckets.delete_cascase(conn, bucket)
    end)

    Map.put(context, :conn, conn)
    |> Map.put(:bucket, bucket)
    |> Map.put(:object_path, object_path)
  end

  test "list objects", %{conn: conn, object_path: object_path} do
    {:ok, objects} = Objects.list(conn, Path.dirname(object_path))
    assert length(objects) == 1
    [object] = objects
    assert object.name == Path.basename(object_path)
    assert object.metadata.mimetype == "image/jpeg"
  end

  test "get object", %{conn: conn, object_path: object_path} do
    {:ok, object} = Objects.get(conn, object_path)
    assert is_binary(object)
  end

  test "copy object", %{conn: conn, bucket: bucket, object_path: object_path} do
    [_bucket_name, path] = String.split(object_path, "/", parts: 2)
    {:ok, %{"Key" => dest}} = Objects.copy(conn, bucket, path, "my/new/path/unsplash.jpg")
    assert dest == "#{bucket.name}/my/new/path/unsplash.jpg"
  end

  test "delete object", %{conn: conn, bucket: bucket, object_path: object_path} do
    {:ok, %{"message" => message}} = Objects.delete(conn, bucket, object_path)
    assert message == "Successfully deleted"
    on_exit(fn -> create_object(conn) end)
  end

  test "generate presigned url", %{conn: conn, object_path: object_path} do
    {:ok, %{"signedURL" => signed_url}} = Objects.sign(conn, object_path)
    assert signed_url =~ "token="
  end

  test "move object", %{conn: conn, bucket: bucket, object_path: object_path} do
    [_bucket_name, path] = String.split(object_path, "/", parts: 2)
    new_path = "my/new/path/unsplash.jpg"
    {:ok, _} = Objects.move(conn, bucket, path, new_path)
    {:error, _} = Objects.get(conn, object_path)
    {:ok, _} = Objects.move(conn, bucket, new_path, path)
  end
end
