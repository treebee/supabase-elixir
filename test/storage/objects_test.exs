defmodule Supabase.Storage.ObjectsTest do
  # use Supabase.ConnectionCase
  use ExUnit.Case

  alias Supabase.Storage.Buckets
  alias Supabase.Storage.Objects

  @bucket_name "testbucket"
  @file_path "test/data/galen-crout-8skNUw3Z1FA-unsplash.jpg"
  @object_path "images/unsplash.jpg"

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

    {:ok, %{"Key" => object_path}} = Objects.create(conn, @bucket_name, @object_path, @file_path)

    # always clean up our test bucket
    on_exit(fn ->
      Buckets.delete_cascase(conn, @bucket_name)
    end)

    Map.put(context, :conn, conn)
    |> Map.put(:bucket, @bucket_name)
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

  test "copy object", %{conn: conn, object_path: object_path} do
    [bucket_name, path] = String.split(object_path, "/", parts: 2)
    {:ok, %{"Key" => dest}} = Objects.copy(conn, bucket_name, path, "my/new/path/unsplash.jpg")
    assert dest == "#{@bucket_name}/my/new/path/unsplash.jpg"
  end

  test "delete object", %{conn: conn, object_path: object_path} do
    # give supabase some time
    Process.sleep(500)
    {:ok, %{"message" => message}} = Objects.delete(conn, "testbucket", object_path)
    assert message == "Successfully deleted"
  end
end
