# Supabase

A Supabase client for Elixir.

## Status

Early work in progress.

Only the [storage](https://supabase.io/storage) OpenAPI [spec](https://supabase.github.io/storage-api/#/) is implemented.

Other functionality will follow.

## Installation

```elixir
def deps do
  [
    {:supabase, git: "https://github.com/treebee/supabase-elixir"}
  ]
end
```

## Usage

The following requires a project and expects disabled _Row Level Security_ for `BUCKETS` and `OBJECTS`.

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

## Testing

The tests require a Supabase project (the **url** and **api key**) where **Row Level Security** is disabled for both, `BUCKET` and `OBJECT`.

```bash
export SUPABASE_TEST_URL="https://*********.supabase.co"
export SUPABASE_TEST_KEY="***"

mix test

# or with coverage
mix coveralls
```
