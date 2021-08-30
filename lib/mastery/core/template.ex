defmodule Mastery.Core.Template do
  @type generators() :: %{
          String.t() => [String.t()] | (() -> String.t())
        }

  @type category() :: atom()

  @type t() :: %__MODULE__{
          name: atom(),
          category: category(),
          instructions: String.t(),
          raw: String.t(),
          compiled: Macro.t(),
          generators: generators(),
          checker: (map(), String.t() -> boolean())
        }

  @type fields() :: keyword()

  @keys [
    :name,
    :category,
    :instructions,
    :raw,
    :compiled,
    :generators,
    :checker
  ]

  @derive {Inspect, except: [:compiled]}
  @enforce_keys @keys
  defstruct @keys

  @spec new(fields()) :: t()
  def new(fields) do
    raw = Keyword.fetch!(fields, :raw)

    struct!(
      __MODULE__,
      Keyword.put(fields, :compiled, EEx.compile_string(raw))
    )
  end
end
