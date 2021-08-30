defmodule Mastery.Examples.Math do
  alias Mastery.Core.Quiz

  def quiz() do
    quiz_fields()
    |> Quiz.new()
    |> Quiz.add_template(template_fields())
  end

  def template_fields() do
    [
      name: :single_digit_addition,
      category: :addition,
      instructions: "Add the numbers",
      raw: "<%= @left %> + <%= @right %>",
      generators: addition_generators(),
      checker: &addition_checker/2
    ]
  end

  defp addition_generators() do
    %{left: Enum.to_list(0..9), right: Enum.to_list(0..9)}
  end

  defp addition_checker(substitutions, answer) do
    left = Keyword.fetch!(substitutions, :left)
    right = Keyword.fetch!(substitutions, :right)

    to_string(left + right) == String.trim(answer)
  end

  def quiz_fields() do
    %{mastery: 2, title: :simple_addition}
  end
end
