defmodule Supabase.Storage do
  @moduledoc """
  Module to work with Supabase storage and the same API the
  [storage-js](https://github.com/supabase/storage-js) client provides.

  """

  alias Supabase.Connection
  alias Supabase.Storage.Buckets
  alias Supabase.Storage.Objects

  @spec list_buckets(Supabase.Connection.t()) ::
          {:error, map} | {:ok, [Supabase.Storage.Bucket.t()]}
  @doc """
  Retrieves the details of all Storage buckets within an existing product.

  ## Notes

    * Policy permissions required
      * `buckets` permissions: `select`
      * `objects` permissions: none

  ## Example

    {:ok, buckets} =
      Supabase.storage(session.access_token)
      |> Supabase.Storage.list_buckets()

  """
  def list_buckets(%Connection{} = conn) do
    Buckets.list(conn)
  end

  @spec list_buckets!(Supabase.Connection.t()) :: [Supabase.Storage.Bucket.t()]
  def list_buckets!(%Connection{} = conn) do
    case list_buckets(conn) do
      {:ok, buckets} -> buckets
      {:error, %{"error" => error}} -> raise error
    end
  end

  @spec get_bucket(Supabase.Connection.t(), binary) ::
          {:error, map} | {:ok, Supabase.Storage.Bucket.t()}
  @doc """
  Retrieves the details of an existing Storage bucket.

  ## Notes

    * Policy permissions required
      * `buckets` permissions: `select`
      * `objects` permissions: none

  ## Example

    {:ok, bucket} =
      Supabase.storage()
      |> Supabase.Storage.get_bucket("avatars")
  """
  def get_bucket(%Connection{} = conn, id) do
    Buckets.get(conn, id)
  end

  @spec get_bucket!(Supabase.Connection.t(), binary) :: Supabase.Storage.Bucket.t()
  def get_bucket!(%Connection{} = conn, id) do
    case Buckets.get(conn, id) do
      {:ok, bucket} -> bucket
      {:error, %{"error" => error}} -> raise error
    end
  end

  @spec create_bucket(Supabase.Connection.t(), binary) :: {:error, map} | {:ok, map}
  @doc """
  Creates a new Storage bucket

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: `insert`
      * `objects` permissions: none

  ## Example

    Supabase.storage(session.access_token)
    |> Supabase.Storage.create_bucket("avatars")

  """
  def create_bucket(%Connection{} = conn, id) do
    Buckets.create(conn, id)
  end

  @spec create_bucket!(Supabase.Connection.t(), binary) :: map
  def create_bucket!(%Connection{} = conn, id) do
    case Buckets.create(conn, id) do
      {:ok, resp} -> resp
      {:error, %{"error" => error}} -> raise error
    end
  end

  @spec empty_bucket(Supabase.Connection.t(), binary | Supabase.Storage.Bucket.t()) ::
          {:error, map} | {:ok, map}
  @doc """
  Removes all objects inside a single bucket.

  ## Notes

    * Policy permissions required
      * `buckets` permissions: `select`
      * `objects` permissions: `select` and `delete`

  ## Example

    Supabase.storage(session.access_token)
    |> Supabase.Storage.empty_bucket("avatars")

  """
  def empty_bucket(%Connection{} = conn, id) do
    Buckets.empty(conn, id)
  end

  @spec delete_bucket(Supabase.Connection.t(), binary | Supabase.Storage.Bucket.t()) ::
          {:error, map} | {:ok, map}
  @doc """
  Deletes an existing bucket. A bucket can't be deleted with existing objects inside it.
  You must first `empty()` the bucket.

  ## Notes

    * Policy permissions required:
      * `buckets` permsisions: `select` and `delete`
      * `objects` permissions: none

  ## Example

    Supabase.storage()
    |> Supabase.Storage.delete_bucket("avatars")

  """
  def delete_bucket(%Connection{} = conn, id) do
    Buckets.delete(conn, id)
  end

  def from(%Connection{} = conn, id) do
    %Connection{conn | bucket: id}
  end

  @spec upload(Supabase.Connection.t(), binary, binary, keyword) :: {:error, map} | {:ok, map}
  @doc """
  Uploads a file to an existing bucket.

  ## Notes

    * Policy permissions required
      * `buckets` permissions: none
      * `objects` permissions: `insert`

  ## Example

  ### Basic

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.upload("public/avatar1.png", "/local/path/to/avatar1.png")

  ### Phoenix Live Upload

    def handle_event("save", _params, socket) do
      uploaded_files =
        consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
          {:ok, %{"Key" => blob_key}} =
            Supabase.storage(socket.assigns.access_token)
            |> Supabase.Storage.from("avatars")
            |> Supabase.Storage.upload(
              "public/" <> entry.client_name, path, content_type: entry.client_type)

          blob_key
        )

      {:noreply, assign(socket, uploaded_files: uploaded_files)}
    end

  """
  def upload(%Connection{bucket: bucket} = conn, path, file, file_options \\ []) do
    Objects.create(conn, bucket, path, file, file_options)
  end

  @spec download(Supabase.Connection.t(), binary | Supabase.Storage.Object.t()) ::
          {:error, map} | {:ok, binary}
  @doc """
  Downloads a file.

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `select`

  ## Examples

    {:ok, blob} =
      Supabase.storage()
      |> Supabase.Storage.from("avatars")
      |> Supabase.Storage.download("public/avatar2.png")

    File.write("/tmp/avatar2.png", blob)

  """
  def download(%Connection{bucket: bucket} = conn, path) do
    Objects.get(conn, bucket, path)
  end

  @spec download!(Supabase.Connection.t(), binary | Supabase.Storage.Object.t()) :: binary
  def download!(%Connection{} = conn, path) do
    case download(conn, path) do
      {:ok, blob} -> blob
      {:error, %{"error" => error}} -> raise error
    end
  end

  @doc """
  Lists all the files within a bucket.

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `select`

  ## Example

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.list(path: "public")

  ## Options

    * `:path` - The folder path

  """
  def list(%Connection{bucket: bucket} = conn, options \\ []) do
    path = Keyword.get(options, :path, "")
    Objects.list(conn, bucket, path, options)
  end

  @doc """
  Replaces an existing file at the specified path with a new one.

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `update` and `select`

  ## Example

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.update("public/avatar1.png", "/my/avatar/file.png")

  ## Options

    HTTP headers, for example `:cache_control`

  """
  def update(%Connection{bucket: bucket} = conn, path, file, file_options \\ []) do
    Objects.update(conn, bucket, path, file, file_options)
  end

  @doc """
  Moves an existing file, optionally renaming it at the same time.

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `update` and `select`

  ## Example

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.move("public/avatar1.png", "private/avatar2.png")

  """
  def move(%Connection{bucket: bucket} = conn, from_path, to_path) do
    Objects.move(conn, bucket, from_path, to_path)
  end

  @doc """
  Deletes files within the same bucket

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `delete` and `select

  ## Example

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.remove(["public/avatar1", "private/avatar2"])

  """
  def remove(%Connection{bucket: bucket} = conn, paths) do
    Objects.delete(conn, bucket, paths)
  end

  @doc """
  Create signed url to download file without requiring permissions.
  This URL can be valid for a set number of seconds.

  ## Notes

    * Policy permissions required:
      * `buckets` permissions: none
      * `objects` permissions: `select

  ## Example

    Supabase.storage()
    |> Supabase.Storage.from("avatars")
    |> Supabase.Storage.create_signed_url("public/avatar1", 60)

  """

  def create_signed_url(%Connection{bucket: bucket} = conn, path, expires_in) do
    Objects.sign(conn, bucket, path, expires_in: expires_in)
  end
end
