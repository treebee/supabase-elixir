defmodule Supabase do
  @moduledoc """
  Elixir library for `Supabase`.

  Combines Supabase Auth, provided by [gotrue-elixir](https://github.com/joshnuss/gotrue-elixir),
  Supabase Database/Rest, via [postgrestex](https://github.com/J0/postgrest-ex), and Supabase
  Storage, implemented in this library.

  Once you configured your application

      config :supabase,
        base_url: <supabase-url>
        api_key: <supabase-anon-key>

  you can initiate the usage of the different services with

  ## Auth

      Supabase.auth()
      |> GoTrue.get_user(access_token)

  ## Database

      Supabase.rest(access_token)
      |> Postgrestex.from("profiles")
      |> Postgrestex.eq("user_id", "1")
      |> Postgrestex.call()

  Instead of `Postgrestex.call()`, `supabase-elixir` provides a `Supabase.json/2` function
  to directly parse the response to a map or struct.

      Supabase.rest(access_token)
      |> Postgrestex.from("profiles")
      |> Postgrestex.eq("user_id", "1")
      |> Supabase.json(keys: :atoms)

  ## Storage

      Supabase.storage(access_token)
      |> Supabase.Storage.from("avatars")
      |> Supabase.Storage.list()

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

  @doc "Entry point for the Storage API"
  def storage() do
    Supabase.Connection.new()
  end

  @doc """
  Entry point for the Storage API for usage in a user context

  ## Example

      Supabase.storage(access_token)
      |> Supabase.Storage.from("avatars")
      |> Supabase.Storage.download("avatar1.png")

  """
  def storage(access_token) do
    Supabase.Connection.new(
      Application.fetch_env!(:supabase, :base_url),
      Application.fetch_env!(:supabase, :api_key),
      access_token
    )
  end

  @doc """
  Entrypoint for the Postgrest library

  ## Example

      Supabase.rest(access_token)
      |> Postgrestex.from("profiles")
      |> Postgrestex.call()

  """
  def rest() do
    init()
  end

  def rest(access_token) when is_binary(access_token) do
    init(access_token: access_token)
  end

  def rest(options), do: init(options)

  def rest(access_token, options) do
    init(Keyword.put(options, :access_token, access_token))
  end

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

  @spec json(map(), keyword()) :: %{
          body: map() | list(),
          status: integer()
        }
  def json(request, options) do
    request
    |> Postgrestex.call()
    |> json(options)
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
