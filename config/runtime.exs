import Config

case Mix.env() do
  :test ->
    config :supabase,
      base_url: System.fetch_env!("SUPABASE_TEST_URL"),
      api_key: System.fetch_env!("SUPABASE_TEST_KEY")

  _ ->
    config :supabase,
      base_url: System.fetch_env!("SUPABASE_URL"),
      api_key: System.fetch_env!("SUPABASE_KEY")
end
