defmodule Supabase.Storage.Bucket do
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          owner: String.t(),
          created_at: String.t(),
          updated_at: String.t()
        }
  defstruct [:id, :name, :owner, :created_at, :updated_at]

  @spec new(map) :: t()
  def new(params) do
    Map.merge(%__MODULE__{}, params)
  end
end
