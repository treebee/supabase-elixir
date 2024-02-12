defmodule Supabase.Storage.ObjectsTest do
  # use Supabase.ConnectionCase
  use ExUnit.Case

  alias Supabase.Storage.Buckets
  alias Supabase.Storage.Objects

  @bucket_name "testbucket"
  @file_path "test/data/galen-crout-8skNUw3Z1FA-unsplash.jpg"
  @object_path "images/unsplash.jpg"
  @second_path "more_images/unsplash.jpg"

  defp create_object(conn) do
    {:ok, %{"Key" => "testbucket/" <> object_path}} =
      Objects.create(conn, @bucket_name, @object_path, @file_path)

    Process.sleep(200)
    object_path
  end

  defp create_object(conn, destination_path, source_path) do
    {:ok, %{"Key" => @bucket_name <> "/" <> destination_path}} =
      Objects.create(conn, @bucket_name, destination_path, source_path)

    Process.sleep(200)
    destination_path
  end

  setup_all context do
    conn = Supabase.TestHelper.connection()

    {:ok, %{"name" => @bucket_name}} =
      case Buckets.create(conn, @bucket_name) do
        {:error, %{"error" => "Duplicate"}} ->
          Supabase.Storage.empty_bucket(conn, @bucket_name)
          Supabase.Storage.delete_bucket(conn, @bucket_name)
          Supabase.Storage.create_bucket(conn, @bucket_name)

        response ->
          response
      end

    {:ok, bucket} = Buckets.get(conn, @bucket_name)
    object_path = create_object(conn)
    second_path = create_object(conn, @second_path, @file_path)
    paths_list = [object_path, second_path]

    # always clean up our test bucket
    on_exit(fn ->
      Buckets.delete_cascase(conn, bucket)
    end)

    Map.put(context, :conn, conn)
    |> Map.put(:bucket, bucket)
    |> Map.put(:object_path, object_path)
    |> Map.put(:paths_list, paths_list)
  end

  test "list objects", %{conn: conn, object_path: object_path} do
    {:ok, objects} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.list(path: Path.dirname(object_path))

    assert length(objects) == 1
    [object] = objects
    assert object.name == Path.basename(object_path)
    assert object.metadata.mimetype == "image/jpeg"
  end

  test "get object", %{conn: conn, object_path: object_path} do
    {:ok, object} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.download(object_path)

    assert is_binary(object)
  end

  test "copy object", %{conn: conn, bucket: bucket, object_path: object_path} do
    {:ok, %{"Key" => dest}} = Objects.copy(conn, bucket, object_path, "my/copy/unsplash.jpg")
    assert dest == "#{bucket.name}/my/copy/unsplash.jpg"
  end

  test "delete object", %{conn: conn, bucket: bucket, object_path: object_path} do
    {:ok, %{"message" => message}} =
      conn |> Supabase.Storage.from(bucket.name) |> Supabase.Storage.remove(object_path)

    assert message == "Successfully deleted"
    on_exit(fn -> create_object(conn) end)
  end

  test "generate presigned url", %{conn: conn, object_path: object_path} do
    {:ok, %{"signedURL" => signed_url}} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.create_signed_url(object_path, 60)

    assert signed_url =~ "token="
  end

  test "generage presigned urls", %{conn: conn, paths_list: paths} do
    {:ok, infos} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.create_signed_urls(paths, 60)

    assert length(infos) == 2
    %{"error" => nil, "signedURL" => "/" <> _} = hd(infos)
  end

  test "move object", %{conn: conn, bucket: bucket, object_path: object_path} do
    new_path = "my/new/path/unsplash.jpg"

    {:ok, _} =
      conn
      |> Supabase.Storage.from(bucket.name)
      |> Supabase.Storage.move(object_path, new_path)

    {:error, _} = Objects.get(conn, bucket.name, object_path)
    {:ok, _} = Objects.move(conn, bucket, new_path, object_path)
  end

  test "update file", %{conn: conn, object_path: object_path} do
    {:ok, _} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.update(object_path, @file_path)
  end

  test "remove files", %{conn: conn, object_path: path} do
    {:ok, file_infos} =
      conn
      |> Supabase.Storage.from(@bucket_name)
      |> Supabase.Storage.remove([path, "not/existent"])

    assert length(file_infos) == 1
    on_exit(fn -> create_object(conn) end)
  end

  test "pagination", %{conn: conn} do
    {:ok, _} = conn |> Supabase.Storage.create_bucket("pagination")

    {:ok, _} =
      conn
      |> Supabase.Storage.from("pagination")
      |> Supabase.Storage.upload("image1.jpg", @file_path)

    {:ok, _} =
      conn
      |> Supabase.Storage.from("pagination")
      |> Supabase.Storage.upload("image2.jpg", @file_path)

    {:ok, objects} =
      conn |> Supabase.Storage.from("pagination") |> Supabase.Storage.list(limit: 1)

    assert length(objects) == 1

    {:ok, objects} =
      conn |> Supabase.Storage.from("pagination") |> Supabase.Storage.list(offset: 1)

    assert length(objects) == 1

    {:ok, objects} =
      conn
      |> Supabase.Storage.from("pagination")
      |> Supabase.Storage.list(sortBy: %{column: "name", order: "desc"})

    assert length(objects) == 2
    [obj1 | _obj2] = objects
    assert obj1.name == "image2.jpg"

    on_exit(fn ->
      Supabase.Storage.empty_bucket(conn, "pagination")
      Supabase.Storage.delete_bucket(conn, "pagination")
    end)
  end
end
