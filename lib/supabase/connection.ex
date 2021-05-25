defmodule Supabase.Connection do
  @type t :: %__MODULE__{
          base_url: String.t(),
          api_key: String.t(),
          access_key: String.t()
        }
  defstruct [:base_url, :api_key, :access_key]

  @spec new :: t()
  def new() do
    new(
      Application.fetch_env!(:supabase, :base_url),
      Application.fetch_env!(:supabase, :api_key),
      Application.fetch_env!(:supabase, :api_key)
    )
  end

  @spec new(String.t(), String.t(), String.t()) :: t()
  def new(base_url, api_key, access_key) do
    %Supabase.Connection{base_url: base_url, api_key: api_key, access_key: access_key}
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
    |> parse_response()
  end

  defp decode_response(body, response_model) do
    case Jason.decode!(body, keys: :atoms) do
      [_ | _] = body -> Enum.map(body, &response_model.new/1)
      body -> response_model.new(body)
    end
  end

  defp decode(request, %Finch.Response{status: status} = response, options) when status < 300 do
    case Keyword.get(options, :response_model) do
      nil -> decode(request, response)
      response_model -> {request, update_in(response.body, &decode_response(&1, response_model))}
    end
  end

  defp decode(request, response, _options), do: decode(request, response)
  defp decode(request, response), do: Req.decode(request, response)

  defp auth_headers(conn) do
    [{"authorization", "Bearer #{conn.access_key}"}, {"apikey", conn.api_key}]
  end

  defp merge_headers(conn, headers) do
    headers =
      headers
      |> Enum.map(fn {name, value} -> {String.downcase(name), value} end)
      |> Map.new()

    Map.merge(Map.new(auth_headers(conn)), headers)
  end

  defp maybe_steps(nil, _step), do: []
  defp maybe_steps(false, _step), do: []
  defp maybe_steps(_, steps), do: steps

  defp parse_response({_, resp}), do: parse_response(resp)

  defp parse_response(%Finch.Response{body: body, status: status}) when status < 400,
    do: {:ok, body}

  defp parse_response(%Finch.Response{body: body}), do: {:error, body}

  defp request_steps(options) do
    [
      &Req.normalize_headers/1,
      &Req.default_headers/1,
      &Req.encode/1
    ] ++
      maybe_steps(options[:params], [&Req.params(&1, options[:params])])
  end
end
