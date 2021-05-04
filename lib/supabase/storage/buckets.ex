defmodule Supabase.Storage.Buckets do
  alias Supabase.Storage.Bucket
  alias Supabase.Connection

  @endpoint "/storage/v1/bucket/"

  @spec list(Connection.t()) :: {:ok, list(Bucket.t())} | {:error, map()}
  def list(%Connection{} = conn) do
    Connection.get(conn, @endpoint, response_model: Bucket)
  end

  @spec get(Connection.t(), String.t()) :: {:error, map()} | {:ok, Bucket.t()}
  def get(%Connection{} = conn, bucket) do
    Connection.get(conn, @endpoint <> bucket, response_model: Bucket)
  end

  @spec create(Connection.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def create(%Connection{} = conn, name) do
    Connection.post(conn, @endpoint, {:json, %{name: name}})
  end

  @spec delete(Connection.t(), String.t() | Bucket.t()) :: {:error, map()} | {:ok, map()}
  def delete(%Connection{} = conn, %Bucket{} = bucket), do: delete(conn, bucket.name)

  def delete(%Connection{} = conn, bucket) do
    case Connection.delete(conn, @endpoint, bucket) do
      %Finch.Response{body: body, status: 200} -> {:ok, body}
      %Finch.Response{body: body} -> {:error, body}
    end
  end

  @spec delete_cascase(Connection.t(), String.t() | Bucket.t()) :: {:error, map()} | {:ok, map()}
  def delete_cascase(%Connection{} = conn, bucket) do
    empty(conn, bucket)
    delete(conn, bucket)
  end

  @spec empty(Connection.t(), String.t() | Bucket.t()) ::
          {:error, map()} | {:ok, map()}
  def empty(%Connection{} = conn, %Bucket{} = bucket), do: empty(conn, bucket.name)

  def empty(%Connection{} = conn, bucket_name) do
    Connection.post(
      conn,
      Path.join(@endpoint, bucket_name <> "/empty"),
      ""
    )
  end
end
