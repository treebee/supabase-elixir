defmodule Supabase.Connection do
  @type t :: %__MODULE__{
          base_url: String.t(),
          api_key: String.t(),
          access_token: String.t(),
          bucket: String.t()
        }
  @enforce_keys [:base_url, :api_key, :access_token]
  defstruct [:base_url, :api_key, :access_token, :bucket]

  @spec new :: t()
  def new() do
    new(
      Application.fetch_env!(:supabase, :base_url),
      Application.fetch_env!(:supabase, :api_key),
      Application.fetch_env!(:supabase, :api_key)
    )
  end

  @spec new(String.t(), String.t()) :: Supabase.Connection.t()
  def new(base_url, api_key) do
    new(base_url, api_key, api_key)
  end

  @spec new(String.t(), String.t(), String.t()) :: t()
  def new(base_url, api_key, access_token) do
    %Supabase.Connection{
      base_url: base_url,
      api_key: api_key,
      access_token: access_token
    }
  end

  @spec post(t(), String.t() | URI.t(), any, keyword) :: any
  def post(%__MODULE__{} = conn, endpoint, body, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    headers = merge_headers(conn, headers) |> Map.to_list()

    url = apply_params(URI.merge(conn.base_url, endpoint), Keyword.get(options, :params))

    Finch.build(
      :post,
      url,
      headers,
      body
    )
    |> encode()
    |> Finch.request(Supabase.Finch)
    |> decode(options)
    |> parse_response()
  end

  @spec get(t(), String.t() | URI.t(), keyword) :: any
  def get(%__MODULE__{} = conn, endpoint, options \\ []) do
    url = URI.merge(conn.base_url, endpoint)

    headers = Keyword.get(options, :headers, [])
    headers = merge_headers(conn, headers) |> Map.to_list()

    url = apply_params(url, Keyword.get(options, :params))

    Finch.build(:get, url, headers)
    |> Finch.request(Supabase.Finch)
    |> decode(options)
    |> parse_response()
  end

  def delete(%__MODULE__{} = conn, endpoint, body) when is_tuple(body) do
    url = conn.base_url |> URI.merge(endpoint)

    Finch.build(:delete, url, [{"Authorization", "Bearer #{conn.access_token}"}], body)
    |> encode()
    |> Finch.request(Supabase.Finch)
    |> decode([])
    |> parse_response()
  end

  @spec delete(Supabase.Connection.t(), String.t() | URI.t(), String.t()) :: any
  def delete(%__MODULE__{} = conn, endpoint, id) do
    url = conn.base_url |> URI.merge(Path.join(endpoint, id))

    Finch.build(:delete, url, [{"Authorization", "Bearer #{conn.access_token}"}])
    |> Finch.request(Supabase.Finch)
    |> decode([])
    |> parse_response()
  end

  defp decode_response(body, response_model) do
    case Jason.decode!(body, keys: :atoms) do
      [_ | _] = body -> Enum.map(body, &response_model.new/1)
      body -> response_model.new(body)
    end
  end

  defp decode({:ok, %Finch.Response{} = response}, options) do
    decode(response, options)
  end

  defp decode(%Finch.Response{status: status, body: body} = response, options)
       when status < 300 do
    with {_, content_type} <- List.keyfind(response.headers, "content-type", 0),
         ["json"] <- MIME.extensions(content_type) do
      case Keyword.get(options, :response_model) do
        nil -> %Finch.Response{status: status, body: Jason.decode!(body)}
        response_model -> update_in(response.body, &decode_response(&1, response_model))
      end
    else
      _ -> response
    end
  end

  defp decode(%Finch.Response{status: status, body: body}, _options) do
    %{status: status, body: Jason.decode!(body)}
  end

  defp auth_headers(conn) do
    [{"authorization", "Bearer #{conn.access_token}"}, {"apikey", conn.api_key}]
  end

  defp merge_headers(conn, headers) do
    headers =
      headers
      |> Enum.map(fn {name, value} -> {String.downcase(name), value} end)
      |> Map.new()

    Map.merge(Map.new(auth_headers(conn)), headers)
  end

  defp parse_response({_, resp}), do: parse_response(resp)

  defp parse_response(%{body: body, status: status}) when status < 400,
    do: {:ok, body}

  defp parse_response(%{body: body}), do: {:error, body}

  defp apply_params(url, nil), do: url
  defp apply_params(url, params), do: URI.to_string(url) <> "?" <> URI.encode_query(params)

  # taken from https://github.com/wojtekmach/req/blob/main/lib/req.ex#L453
  defp encode(request) do
    case request.body do
      {:form, data} ->
        request
        |> Map.put(:body, URI.encode_query(data))
        |> put_new_header("content-type", "application/x-www-form-urlencoded")

      {:json, data} ->
        request
        |> Map.put(:body, Jason.encode_to_iodata!(data))
        |> put_new_header("content-type", "application/json")

      _other ->
        request
    end
  end

  defp put_new_header(struct, name, value) do
    if Enum.any?(struct.headers, fn {key, _} -> String.downcase(key) == name end) do
      struct
    else
      put_header(struct, name, value)
    end
  end

  defp put_header(struct, name, value) do
    update_in(struct.headers, &[{name, value} | &1])
  end
end
