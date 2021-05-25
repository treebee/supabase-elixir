defmodule Supabase.Storage do
  @moduledoc """
  Module to work with Supabase storage and the same API the
  [storage-js](https://github.com/supabase/storage-js) client provides.

  """

  alias Supabase.Connection
  alias Supabase.Storage.Buckets

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
  end

  def upload(%Connection{} = conn, path, file, file_options \\ []) do
  end

  def download(%Connection{} = conn, path) do
  end

  def list(%Connection{} = conn, options \\ []) do
  end

  def update(%Connection{} = conn, path, file, file_options \\ []) do
  end

  def move(%Connection{} = conn, from_path, to_path) do
  end

  def remove(%Connection{} = conn, paths) do
  end

  def create_signed_url(%Connection{} = conn, path, expires_in) do
  end
end
