defmodule Supabase do
  @moduledoc """
  Elixir library for `Supabase`.
  """

  @doc """
  Returns a client that can be used for functions of the GoTrue library.

  Example

    iex> Supabase.auth() |> GoTrue.settings()
    %{
      "autoconfirm" => false,
      "disable_signup" => false,
      "external" => %{
        "azure" => false,
        "bitbucket" => false,
        "email" => true,
        "facebook" => false,
        "github" => true,
        "gitlab" => false,
        "google" => false,
        "saml" => false
    },
      "external_labels" => %{}
    }
  """
  def auth() do
    {url, api_key} = connection_details()
    auth(url, api_key)
  end

  def auth(base_url, api_key) do
    base_url
    |> URI.merge("/auth/v1")
    |> URI.to_string()
    |> GoTrue.client(api_key)
  end

  @doc """
  Entrypoint for implementing the same API the JS library does.
  """
  def storage() do
    raise "This version of the storage API is not implemented yet"
  end

  @doc """

  """
  def init(options \\ []) do
    {url, api_key} = connection_details()
    init(url, api_key, options)
  end

  def init(base_url, api_key, options \\ []) do
    schema = Keyword.get(options, :schema, "public")
    jwt = Keyword.get(options, :access_token, api_key)

    req =
      Postgrestex.init(schema, URI.to_string(URI.merge(base_url, "/rest/v1")))
      |> Postgrestex.auth(jwt)

    update_in(req.headers, &Map.merge(&1, %{apikey: api_key}))
  end

  @spec json({:ok, HTTPoison.Response.t()} | HTTPoison.Response.t()) :: %{
          body: map() | list(),
          status: integer()
        }
  def json(_response, options \\ [])

  def json({:ok, %HTTPoison.Response{} = response}, options) do
    json(response, options)
  end

  def json(%HTTPoison.Response{body: body, status_code: status}, options) do
    %{body: decode_body(body, options), status: status}
  end

  defp decode_body(body, options) do
    {_, body} = Jason.decode(body, options)
    body
  end

  defp connection_details() do
    {Application.fetch_env!(:supabase, :base_url), Application.fetch_env!(:supabase, :api_key)}
  end

  def storage_url() do
    URI.merge(Application.fetch_env!(:supabase, :base_url), "/storage/v1") |> URI.to_string()
  end
end
