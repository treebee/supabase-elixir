defmodule Supabase do
  @moduledoc """
  Elixir library for `Supabase`.
  """

  def auth(), do: GoTrue

  @doc """
  Entrypoint for implementing the same API the JS library does.
  """
  def storage() do
    raise "This version of the storage API is not implemented yet"
  end

  @doc """

  """
  def init(options \\ []) do
    schema = Keyword.get(options, :schema, "public")
    jwt = Keyword.get(options, :access_token, Application.get_env(:supabase, :api_key))
    url = URI.merge(Application.fetch_env!(:supabase, :base_url), "/rest/v1")

    req = Postgrestex.init(schema, url)
    update_in(req.headers, &Map.merge(&1, %{apikey: jwt}))
    # sets the wrong header
    # |> Postgrestex.auth(jwt)
  end

  def json(%HTTPoison.Response{body: body, status_code: status}) do
    %{body: decode_body(body), status: status}
  end

  defp decode_body(body) do
    {_, body} = Jason.decode(body)
    body
  end
end
