defmodule Supabase.Storage.Object do
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          owner: String.t(),
          bucket_id: String.t(),
          created_at: String.t(),
          updated_at: String.t(),
          last_accessed_at: String.t(),
          metadata: map()
        }
  defstruct [
    :id,
    :name,
    :owner,
    :bucket_id,
    :created_at,
    :updated_at,
    :last_accessed_at,
    :metadata
  ]

  @spec new(map) :: t()
  def new(params) do
    Map.merge(%__MODULE__{}, params)
  end
end
