defmodule Supabase.Connection do
  @type t :: %__MODULE__{
          base_url: String.t(),
          api_key: String.t()
        }
  defstruct [
    :base_url,
    :api_key
  ]

  @spec new(String.t(), String.t()) :: t()
  def new(base_url, api_key) do
    %Supabase.Connection{base_url: base_url, api_key: api_key}
  end

  @spec post(t(), String.t() | URI.t(), any, list({String.t(), String.t()})) :: any
  def post(%__MODULE__{} = conn, endpoint, body, headers \\ []) do
    headers =
      Map.new([
        {
          "Authorization",
          "Bearer #{conn.api_key}"
        },
        {"apiKey", conn.api_key}
      ])
      |> Map.merge(Map.new(headers))

    Req.post!(
      URI.merge(conn.base_url, endpoint),
      body,
      headers: headers
    )
  end

  @spec get(t(), String.t() | URI.t(), keyword()) :: any
  def get(%__MODULE__{} = conn, endpoint, options \\ []) do
    headers =
      Map.new([
        {
          "Authorization",
          "Bearer #{conn.api_key}"
        },
        {"apiKey", conn.api_key}
      ])
      |> Map.merge(Map.new(Keyword.get(options, :headers, [])))
      |> Map.to_list()

    url = URI.merge(conn.base_url, endpoint)

    Req.get!(
      url,
      params: Keyword.get(options, :params, []),
      headers: headers
    )
  end

  @spec delete(Supabase.Connection.t(), String.t() | URI.t(), String.t()) :: any
  def delete(%__MODULE__{} = conn, endpoint, id) do
    url = conn.base_url |> URI.merge(endpoint) |> URI.merge(id)
    Req.request!(:delete, url, headers: [{"Authorization", "Bearer #{conn.api_key}"}])
  end

  @spec create_list_response(Finch.Response.t(), module()) ::
          {:error, %{body: map(), status: integer()}} | {:ok, list()}
  def create_list_response(%Finch.Response{body: body, status: 200}, module) do
    {:ok,
     body
     |> Stream.map(&Jason.encode!/1)
     |> Stream.map(&Jason.decode!(&1, keys: :atoms))
     |> Enum.map(&module.new/1)}
  end

  def create_list_response(%Finch.Response{body: body, status: status}, _module) do
    {:error, %{body: body, status: status}}
  end
end
