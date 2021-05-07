import Config

config :supabase,
  base_url: System.get_env("SUPABASE_URL"),
  api_key: System.get_env("SUPABASE_KEY")
