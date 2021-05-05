import Config

config :supabase,
  base_url: System.get_env("SUPABASE_URL"),
  api_key: System.get_env("SUPABASE_KEY")

config :gotrue,
  base_url: URI.to_string(URI.merge(System.get_env("SUPABASE_URL"), "/auth/v1")),
  access_token: System.get_env("SUPABASE_KEY")
