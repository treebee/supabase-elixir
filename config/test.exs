import Config

config :supabase,
  base_url: System.get_env("SUPABASE_TEST_URL"),
  api_key: System.get_env("SUPABASE_TEST_KEY")
