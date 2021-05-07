defmodule Supabase do
  @moduledoc """
  Elixir library for `Supabase`.
  """

  @doc """
  Entrypoint for implementing the same API the JS library does.
  """
  def storage() do
    raise "This version of the storage API is not implemented yet"
  end

  @doc """

  """
  def init(options \\ []) do
    api_key = Application.fetch_env!(:supabase, :api_key)
    url = Application.fetch_env!(:supabase, :base_url)
    init(url, api_key, options)
  end

  def init(base_url, api_key, options \\ []) do
    schema = Keyword.get(options, :schema, "public")
    jwt = Keyword.get(options, :access_token, api_key)

    req =
      Postgrestex.init(schema, URI.merge(base_url, "/rest/v1"))
      |> Postgrestex.auth(jwt)

    update_in(req.headers, &Map.merge(&1, %{apikey: api_key}))
  end

  def json(%HTTPoison.Response{body: body, status_code: status}) do
    %{body: decode_body(body), status: status}
  end

  defp decode_body(body) do
    {_, body} = Jason.decode(body)
    body
  end
end
