defmodule Supabase.Storage.Objects do
  alias Supabase.Connection
  alias Supabase.Storage.Bucket
  alias Supabase.Storage.Object

  # TODO pagination
  def list(conn, path) do
    [bucket, path] = split_path(path)
    list(conn, bucket, path)
  end

  @spec list(Connection.t(), String.t() | Bucket.t(), String.t()) ::
          {:ok, list(Object.t())} | {:error, map()}
  def list(conn, bucket, folder)

  def list(%Connection{} = conn, %Bucket{} = bucket, folder),
    do: list(conn, bucket.name, folder)

  def list(%Connection{} = conn, bucket, folder) do
    Connection.post(conn, "/storage/v1/object/list/#{bucket}", {:json, %{prefix: folder}})
    |> Connection.create_list_response(Object)
  end

  @spec get(Connection.t(), String.t()) :: {:error, map()} | {:ok, binary()}
  def get(conn, path) do
    [bucket, path] = split_path(path)

    get(conn, bucket, path)
  end

  @spec get(Connection.t(), Bucket.t(), Object.t()) :: {:error, map()} | {:ok, binary()}
  def get(%Connection{} = conn, %Bucket{} = bucket, %Object{} = object),
    do: get(conn, bucket.name, object.name)

  @spec get(Connection.t(), String.t(), String.t()) :: {:error, map()} | {:ok, binary()}
  def get(conn, bucket, object) do
    case Connection.get(conn, "/storage/v1/object/#{bucket}/#{object}") do
      %Finch.Response{status: 200, body: body} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  @spec create(Connection.t(), String.t() | Bucket.t(), String.t(), String.t()) ::
          {:error, map()} | {:ok, map()}
  def create(%Connection{} = conn, %Bucket{} = bucket, object_path, file),
    do: create(conn, bucket.name, object_path, file)

  def create(%Connection{} = conn, bucket_name, object_path, file) do
    # TODO: figure out how to get multipart working with Req/Finch to avoid the Tesla dependency
    mp =
      Tesla.Multipart.new()
      |> Tesla.Multipart.add_file(file,
        filename: object_path,
        headers: [{"Content-Type", MIME.from_path(file)}]
      )

    middleware = [
      {Tesla.Middleware.BaseUrl, conn.base_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{conn.api_key}"}]}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Finch, [name: Req.Finch]})

    case Tesla.post(client, "/storage/v1/object/#{Path.join([bucket_name, object_path])}", mp) do
      {:ok, %Tesla.Env{body: body}} -> {:ok, Jason.decode!(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec copy(Connection.t(), Storage.Bucket.t(), String.t(), String.t()) ::
          {:error, map()} | {:ok, map()}
  def copy(%Connection{} = conn, %Bucket{} = bucket, source_key, destination_key),
    do: copy(conn, bucket.name, source_key, destination_key)

  def copy(%Connection{} = conn, bucket_name, source_key, destination_key) do
    case Connection.post(
           conn,
           "/storage/v1/object/copy",
           {:json,
            %{bucketId: bucket_name, sourceKey: source_key, destinationKey: destination_key}}
         ) do
      %Finch.Response{body: body, status: 200} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  @spec move(Connection.t(), Storage.Bucket.t(), String.t(), String.t()) ::
          {:error, map()} | {:ok, map()}
  def move(%Connection{} = conn, %Bucket{} = bucket, source_key, destination_key),
    do: move(conn, bucket.name, source_key, destination_key)

  def move(%Connection{} = conn, bucket_name, source_key, destination_key) do
    case Connection.post(
           conn,
           "/storage/v1/object/move",
           {:json,
            %{bucketId: bucket_name, sourceKey: source_key, destinationKey: destination_key}}
         ) do
      %Finch.Response{body: body, status: 200} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  @spec delete(Connection.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def delete(%Connection{} = conn, full_path) do
    [bucket, path] = split_path(full_path)
    delete(conn, bucket, path)
  end

  @spec delete(Connection.t(), Bucket.t() | String.t(), String.t()) ::
          {:ok, map()} | {:error, map()}
  def delete(%Connection{} = conn, %Bucket{} = bucket, object_path),
    do: delete(conn, bucket.name, object_path)

  def delete(%Connection{} = conn, bucket_name, object_path) do
    case Connection.delete(conn, "/storage/v1/object/#{bucket_name}", object_path) do
      %Finch.Response{status: 200, body: body} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  @spec sign(Connection.t(), String.t()) :: {:error, map()} | {:ok, map()}
  def sign(conn, full_path) do
    [bucket, path] = split_path(full_path)
    sign(conn, bucket, path)
  end

  @spec sign(Connection.t(), Bucket.t() | String.t(), String.t(), keyword) ::
          {:error, map()} | {:ok, map()}
  def sign(conn, bucket, object_path, opts \\ [])

  def sign(%Connection{} = conn, %Bucket{} = bucket, object_path, opts),
    do: sign(conn, bucket.name, object_path, opts)

  def sign(%Connection{} = conn, bucket_name, object_path, opts) do
    expires_in = Keyword.get(opts, :expires_in, 60_000)

    case Connection.post(
           conn,
           "/storage/v1/object/sign/#{bucket_name}/#{object_path}",
           {:json, %{expiresIn: expires_in}}
         ) do
      %Finch.Response{body: body, status: 200} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  defp split_path(path) do
    case String.split(path, "/", parts: 2) do
      [bucket] -> [bucket, ""]
      [bucket, path] -> [bucket, path]
    end
  end
end
