defmodule Supabase.Storage.Objects do
  alias Supabase.Connection
  alias Supabase.Storage.Bucket
  alias Supabase.Storage.Object

  @endpoint "/storage/v1/object"

  @spec list(Connection.t(), String.t() | Bucket.t(), String.t(), keyword()) ::
          {:ok, list(Object.t())} | {:error, map()}
  def list(conn, bucket, folder, options \\ [])

  def list(%Connection{} = conn, %Bucket{} = bucket, folder, options),
    do: list(conn, bucket.name, folder, options)

  def list(%Connection{} = conn, bucket, folder, options) do
    body = %{prefix: folder}
    body = apply_pagination(body, options)
    Connection.post(conn, "#{@endpoint}/list/#{bucket}", {:json, body}, response_model: Object)
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
    Connection.get(conn, "#{@endpoint}/#{bucket}/#{object}")
  end

  @spec create(Connection.t(), String.t() | Bucket.t(), String.t(), String.t(), keyword()) ::
          {:error, map()} | {:ok, map()}
  def create(conn, bucket, object_path, file, opts \\ [])

  def create(%Connection{} = conn, %Bucket{} = bucket, object_path, file, opts),
    do: create(conn, bucket.name, object_path, file, opts)

  def create(%Connection{} = conn, bucket_name, object_path, file, opts) do
    upload_file(conn, bucket_name, object_path, file, opts)
  end

  @spec copy(Connection.t(), Storage.Bucket.t(), String.t(), String.t()) ::
          {:error, map()} | {:ok, map()}
  def copy(%Connection{} = conn, %Bucket{} = bucket, source_key, destination_key),
    do: copy(conn, bucket.name, source_key, destination_key)

  def copy(%Connection{} = conn, bucket_name, source_key, destination_key) do
    Connection.post(
      conn,
      "#{@endpoint}/copy",
      {:json, %{bucketId: bucket_name, sourceKey: source_key, destinationKey: destination_key}}
    )
  end

  @spec move(Connection.t(), Storage.Bucket.t(), String.t(), String.t()) ::
          {:error, map()} | {:ok, map()}
  def move(%Connection{} = conn, %Bucket{} = bucket, source_key, destination_key),
    do: move(conn, bucket.name, source_key, destination_key)

  def move(%Connection{} = conn, bucket_name, source_key, destination_key) do
    Connection.post(
      conn,
      "#{@endpoint}/move",
      {:json, %{bucketId: bucket_name, sourceKey: source_key, destinationKey: destination_key}}
    )
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

  def delete(%Connection{} = conn, bucket_name, object_path) when is_binary(object_path) do
    Connection.delete(conn, "#{@endpoint}/#{bucket_name}", object_path)
  end

  def delete(%Connection{} = conn, bucket_name, object_paths) when is_list(object_paths) do
    Connection.delete(conn, "#{@endpoint}/#{bucket_name}", {:json, %{prefixes: object_paths}})
  end

  @spec sign(Connection.t(), String.t()) :: {:error, map()} | {:ok, map()}
  def sign(conn, full_path) do
    [bucket, path] = split_path(full_path)
    sign(conn, bucket, path)
  end

  @spec sign(Connection.t(), Bucket.t() | String.t(), String.t(), keyword) ::
          {:error, map()} | {:ok, map()}
  def sign(conn, bucket, object_path, opts \\ [])

  def sign(%Connection{} = conn, %Bucket{} = bucket, object_path, opts)
      when is_binary(object_path),
      do: sign(conn, bucket.name, object_path, opts)

  def sign(%Connection{} = conn, %Bucket{} = bucket, object_paths, opts)
      when is_list(object_paths),
      do: sign(conn, bucket.name, object_paths, opts)

  def sign(%Connection{} = conn, bucket_name, object_paths, opts) when is_list(object_paths) do
    expires_in = Keyword.get(opts, :expires_in, 60_000)

    Connection.post(
      conn,
      "#{@endpoint}/sign/#{bucket_name}",
      {:json, %{expiresIn: expires_in, paths: object_paths}}
    )
  end

  def sign(%Connection{} = conn, bucket_name, object_path, opts) do
    expires_in = Keyword.get(opts, :expires_in, 60_000)

    Connection.post(
      conn,
      "#{@endpoint}/sign/#{bucket_name}/#{object_path}",
      {:json, %{expiresIn: expires_in}}
    )
  end

  def update(%Connection{} = conn, bucket, path, file, opts) do
    upload_file(conn, bucket, path, file, Keyword.put(opts, :method, :put))
  end

  defp split_path(path) do
    case String.split(path, "/", parts: 2) do
      [bucket] -> [bucket, ""]
      [bucket, path] -> [bucket, path]
    end
  end

  defp upload_file(conn, bucket_name, object_path, file, opts) do
    method = Keyword.get(opts, :method, :post)

    # TODO: figure out how to get multipart working with Finch to avoid the Tesla dependency
    mp =
      Tesla.Multipart.new()
      |> Tesla.Multipart.add_file(file,
        filename: object_path,
        headers: [{"Content-Type", Keyword.get(opts, :content_type, MIME.from_path(file))}]
      )

    middleware = [
      {Tesla.Middleware.BaseUrl, conn.base_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{conn.access_token}"}]}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Finch, [name: Supabase.Finch]})

    resp =
      case method do
        :post -> Tesla.post(client, "#{@endpoint}/#{Path.join([bucket_name, object_path])}", mp)
        :put -> Tesla.put(client, "#{@endpoint}/#{Path.join([bucket_name, object_path])}", mp)
      end

    case resp do
      {:ok, %Tesla.Env{body: body}} -> {:ok, Jason.decode!(body)}
      {:error, error} -> {:error, error}
    end
  end

  defp apply_pagination(body, options) do
    body
    |> maybe_option(options, :limit)
    |> maybe_option(options, :offset)
    |> maybe_option(options, :sortBy)
  end

  defp maybe_option(body, options, key) do
    case options[key] do
      nil -> body
      value -> Map.put(body, key, value)
    end
  end
end
