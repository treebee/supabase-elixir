> :warning: For using Supabase with Elixir, consider using the actively maintained https://github.com/zoedsoupe/supabase-ex

# Supabase

A Supabase client for Elixir.

[![.github/workflows/ci.yml](https://github.com/treebee/supabase-elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/treebee/supabase-elixir/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/treebee/supabase-elixir/badge.svg?branch=main)](https://coveralls.io/github/treebee/supabase-elixir?branch=main)

With this library you can work with [Supabase](https://supabase.io). At the moment there's
functionality for

- **auth**
- **database/postgrest**
- **storage**

**auth** and **database** are implemented in different libraries.
[gotrue-elixir](https://github.com/joshnuss/gotrue-elixir) for **auth** and
[postgrest-ex](https://github.com/J0/postgrest-ex) for **database**.

**supabase-elixir** handles the correct initializtion from a common config.

## Installation

```elixir
def deps do
  [
    {:supabase, "~> 0.2.0"}
  ]
end
```

## Configuration

You can configure your Supabase project url and api anon key so that **supabase-elixir**
can handle the correct initialization of the different clients:

```elixir
config :supabase,
  base_url: System.get_env("SUPABASE_URL"),
  api_key: System.get_env("SUPABASE_KEY")
```

## Auth / GoTrue

Uses [gotrue-elixir](https://github.com/joshnuss/gotrue-elixir)

```elixir
Supabase.auth()
|> GoTrue.settings()
```

## Database / Postgrest

Uses [postgrest-ex](https://github.com/J0/postgrest-ex):

```elixir
import Supabase
import Postgrestex

Supabase.rest()
|> from("profiles")
|> eq("Username", "Patrick")
|> json()
%{
  body: [
    %{
      "avatar_url" => "avatar.jpeg",
      "id" => "blabla7d-411d-4ead-83d0-452343b",
      "updated_at" => "2021-05-02T21:05:37.258616+00:00",
      "username" => "Patrick",
      "website" => "https://patrick-muehlbauer.com"
    }
  ],
  status: 200
}

# Or when in a user context with available JWT
Supabase.rest(session.access_token)

# To use another schema than 'public'
Supabase.rest(schema: 'other_schema')
```

### Not depending on Application config

```elixir
Supabase.init("https://my-project.supabase.co", "my-api-key")
```

## Storage

The API tries to reflect the one of the offical [JS client](https://github.com/supabase/storage-js).

```elixir
{:ok, object} =
  Supabase.storage()
  |> Supabase.Storage.from("avatars")
  |> Supabase.Storage.download("public/avatar1.png")

# with user context
{:ok, object} =
  Supabase.storage(user.access_token)
  |> Supabase.Storage.from("avatars")
  |> Supabase.Storage.download("public/avatar1.png")

```

## Testing

The tests require a Supabase project (the **url** and **api key**) where **Row Level Security** is disabled for both, `BUCKET` and `OBJECT`.

```bash
export SUPABASE_TEST_URL="https://*********.supabase.co"
export SUPABASE_TEST_KEY="***"

mix test

# or with coverage
mix coveralls
```
