defmodule Mastery.Core.Question do
  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:template]}
  defstruct [
    :asked,
    :substitutions,
    :template
  ]

  alias Mastery.Core.Template

  @spec new(Template.t()) :: t()
  def new(template) do
    template.generators
    |> Enum.map(&mk_substitution/1)
    |> evaluate(template)
  end

  defp mk_substitution({name, choices_or_generator}) do
    {name, choose(choices_or_generator)}
  end

  defp choose(choices) when is_list(choices) do
    Enum.random(choices)
  end

  defp choose(generator) when is_function(generator) do
    generator.()
  end

  defp compile(substitutions, template) do
    template.compiled
    |> Code.eval_quoted(assigns: substitutions)
    |> elem(0)
  end

  defp evaluate(substitutions, template) do
    %__MODULE__{
      asked: compile(substitutions, template),
      substitutions: substitutions,
      template: template
    }
  end
end
