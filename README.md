# Supabase

A Supabase client for Elixir.

[![.github/workflows/ci.yml](https://github.com/treebee/supabase-elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/treebee/supabase-elixir/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/treebee/supabase-elixir/badge.svg?branch=main)](https://coveralls.io/github/treebee/supabase-elixir?branch=main)

**Early work in progress.**

## Database

Uses [postgrest-ex](https://github.com/J0/postgrest-ex):

```elixir
import Supabase
import Postgrestex

Supabase.init()
|> from("profiles")
|> eq("Username", "Patrick")
|> call()
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
Supabase.init(access_token: session.access_token)

# To use another schema than 'public'
Supabase.init('other_schema')
```

## Storage

Implements the [storage](https://supabase.io/storage) OpenAPI [spec](https://supabase.github.io/storage-api/#/), see examples below.
Another API reflecting the one of the JS client will follow.

### Create a Connection

```elixir
iex> conn = Supabase.Connection.new(
  System.get_env("SUPABASE_URL"),
  System.get_env("SUPABASE_KEY")
)
%Supabase.Connection{
  api_key: "***",
  base_url: "https://*************.supabase.co"
}
```

### Create a new Bucket

```elixir
iex> {:ok, %{"name" => bucket_name}} = Supabase.Storage.Buckets.create(conn, "avatars")
{:ok, %{"name" => "avatars"}}
iex> {:ok, %Supabase.Storage.Bucket{} = bucket} = Supabase.Storage.Buckets.get(conn, "avatars")
{:ok,
 %Supabase.Storage.Bucket{
   created_at: "2021-04-30T16:47:49.925325+00:00",
   id: "avatars",
   name: "avatars",
   owner: "",
   updated_at: "2021-04-30T16:47:49.925325+00:00"
 }}
```

### Upload an Image to the new Bucket

```elixir
iex> {:ok, %{"Key" => object_key} = Supabase.Storage.Objects.create(conn, bucket, "images/avatar.jpg", "~/Pictures/avatar.png")
{:ok, %{"Key" => "avatars/images/avatar.jpg"}}
iex> {:ok, objects} = Supabase.Storage.Objects.list(conn, bucket, "images")
{:ok,
 [
   %Supabase.Storage.Object{
     bucket_id: nil,
     created_at: "2021-04-30T16:53:46.41036+00:00",
     id: "e1ff915f-b6b0-46ae-b1f0-a5e85adebdc8",
     last_accessed_at: "2021-04-30T16:53:46.41036+00:00",
     metadata: %{cacheControl: "no-cache", mimetype: "image/png", size: 83001},
     name: "avatar.jpg",
     owner: nil,
     updated_at: "2021-04-30T16:53:46.41036+00:00"
   }
 ]}
```

### Auth (GoTrue)

Directly uses [gotrue-elixir](https://github.com/joshnuss/gotrue-elixir) as

```elixir
Supabase.auth()

# e.g.
Supabase.auth().get_user("my-jwt-token")
```

## Installation

```elixir
def deps do
  [
    {:supabase, git: "https://github.com/treebee/supabase-elixir"}
  ]
end
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
