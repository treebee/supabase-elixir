defmodule Supabase.Connection do
  @type t :: %__MODULE__{
          base_url: String.t(),
          api_key: String.t()
        }
  defstruct [
    :base_url,
    :api_key
  ]

  @spec new :: t()
  def new(), do: new(System.get_env("SUPABASE_URL"), System.get_env("SUPABASE_KEY"))

  @spec new(String.t(), String.t()) :: t()
  def new(base_url, api_key) do
    %Supabase.Connection{base_url: base_url, api_key: api_key}
  end

  @spec post(t(), String.t() | URI.t(), any, keyword) :: any
  def post(%__MODULE__{} = conn, endpoint, body, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    headers = merge_headers(conn, headers)
    options = Keyword.put(options, :headers, headers)

    Req.build(
      :post,
      URI.merge(conn.base_url, endpoint),
      body: body,
      headers: headers
    )
    |> Req.add_request_steps(request_steps(options))
    |> Req.add_response_steps([
      &Req.decompress/2,
      &decode(&1, &2, options)
    ])
    |> Req.run()
    |> parse_response()
  end

  defp request_steps(options) do
    [
      &Req.normalize_headers/1,
      &Req.default_headers/1,
      &Req.encode/1
    ] ++
      maybe_steps(options[:params], [&Req.params(&1, options[:params])])
  end

  @spec get(t(), String.t() | URI.t(), keyword) :: any
  def get(%__MODULE__{} = conn, endpoint, options \\ []) do
    url = URI.merge(conn.base_url, endpoint)

    headers = Keyword.get(options, :headers, [])
    headers = merge_headers(conn, headers)
    options = Keyword.put(options, :headers, headers)

    Req.build(:get, url, options)
    |> Req.add_request_steps(request_steps(options))
    |> Req.add_response_steps([
      &Req.decompress/2,
      &decode(&1, &2, options)
    ])
    |> Req.run()
    |> parse_response()
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

  def put_header(request, []), do: request

  def put_header(request, [{name, value} | rest]) do
    update_in(request.headers, &[{name, value} | &1])
    |> put_header(rest)
  end

  def decode_response(body, response_model) do
    case Jason.decode!(body, keys: :atoms) do
      [_ | _] = body -> Enum.map(body, &response_model.new/1)
      body -> response_model.new(body)
    end
  end

  def decode(request, %Finch.Response{status: status} = response, options) when status < 300 do
    case Keyword.get(options, :response_model) do
      nil -> decode(request, response)
      response_model -> {request, update_in(response.body, &decode_response(&1, response_model))}
    end
  end

  def decode(request, response, _options), do: decode(request, response)
  def decode(request, response), do: Req.decode(request, response)

  defp auth_headers(conn),
    do: [{"authorization", "Bearer #{conn.api_key}"}, {"apikey", conn.api_key}]

  def merge_headers(conn, headers) do
    headers =
      headers
      |> Enum.map(fn {name, value} -> {String.downcase(name), value} end)
      |> Map.new()

    Map.merge(Map.new(auth_headers(conn)), headers)
  end

  defp maybe_steps(nil, _step), do: []
  defp maybe_steps(false, _step), do: []
  defp maybe_steps(_, steps), do: steps

  defp parse_response({_, %Finch.Response{body: body, status: status}}) when status < 400,
    do: {:ok, body}

  defp parse_response({_, %Finch.Response{body: body}}), do: {:error, body}
end
