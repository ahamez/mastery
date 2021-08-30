defmodule Mastery.Core.Quiz do
  alias Mastery.Core.{Question, Response, Template}

  @derive {Inspect, except: [:templates]}

  @type t() :: %__MODULE__{
          title: atom() | nil,
          mastery: number(),
          templates: %{Template.category() => [Template.t()]},
          used: list(),
          mastered: list(),
          current_question: Question.t() | nil,
          last_response: Response.t() | nil,
          record: map()
        }

  defstruct title: nil,
            mastery: 3,
            templates: %{},
            used: [],
            mastered: [],
            current_question: nil,
            last_response: nil,
            record: %{}

  # ------------------------------------------------------------------------------------------- #

  @spec new(keyword() | map()) :: t()
  def new(fields) do
    struct!(__MODULE__, fields)
  end

  # ------------------------------------------------------------------------------------------- #

  def add_template(quiz, template_fields) do
    template = Template.new(template_fields)

    templates =
      update_in(
        quiz.templates,
        [template.category],
        &add_to_list_or_nil(&1, template)
      )

    %{quiz | templates: templates}
  end

  defp add_to_list_or_nil(nil, template), do: [template]
  defp add_to_list_or_nil(templates, template), do: [template | templates]

  # ------------------------------------------------------------------------------------------- #

  def select_question(%__MODULE__{templates: templates}) when map_size(templates) == 0, do: nil

  def select_question(quiz) do
    quiz
    |> set_current_question()
    |> move_template(:used)
    |> reset_template_cycle()
  end

  defp set_current_question(quiz) do
    %{quiz | current_question: select_random_question(quiz)}
  end

  defp select_random_question(quiz) do
    quiz.templates
    |> Enum.random()
    |> elem(1)
    |> Enum.random()
    |> Question.new()
  end

  defp move_template(quiz, field) do
    quiz
    |> remove_template_from_category()
    |> add_template_to_field(field)
  end

  defp remove_template_from_category(quiz) do
    current_template = quiz.current_question.template

    new_category_templates =
      quiz.templates
      |> Map.fetch!(current_template.category)
      |> List.delete(current_template)

    new_templates =
      case new_category_templates do
        [] -> Map.delete(quiz.templates, current_template.category)
        _ -> Map.put(quiz.templates, current_template.category, new_category_templates)
      end

    %{quiz | templates: new_templates}
  end

  defp add_template_to_field(quiz, field) do
    current_template = quiz.current_question.template
    field_list = Map.get(quiz, field)

    Map.put(quiz, field, [current_template | field_list])
  end

  defp reset_template_cycle(%{templates: templates, used: used} = quiz)
       when map_size(templates) == 0 do
    %{quiz | templates: Enum.group_by(used, fn template -> template.category end), used: []}
  end

  defp reset_template_cycle(quiz), do: quiz

  # ------------------------------------------------------------------------------------------- #

  def answer_question(quiz, %Response{correct: true} = response) do
    quiz
    |> inc_record()
    |> save_response(response)
    |> maybe_advance()
  end

  def answer_question(quiz, %Response{correct: false} = response) do
    quiz
    |> reset_record
    |> save_response(response)
  end

  defp save_response(quiz, response) do
    %{quiz | last_response: response}
  end

  defp mastered?(quiz) do
    current_template = quiz.current_question.template
    score = Map.get(quiz.record, current_template.name, 0)

    score == quiz.mastery
  end

  defp inc_record(%__MODULE__{current_question: question} = quiz) do
    new_record = Map.update(quiz.record, question.template.name, 1, &(&1 + 1))

    %{quiz | record: new_record}
  end

  # defp maybe_advance(quiz, _mastered = false), do: quiz
  # defp maybe_advance(quiz, _mastered = true), do: advance(quiz)

  defp maybe_advance(quiz) do
    if mastered?(quiz) do
      advance(quiz)
    else
      quiz
    end
  end

  defp advance(quiz) do
    quiz
    |> move_template(:mastered)
    |> reset_record()
    |> reset_used()
  end

  defp reset_record(%{current_question: question} = quiz) do
    %{quiz | record: Map.delete(quiz.record, question.template.name)}
  end

  defp reset_used(%{current_question: question} = quiz) do
    %{quiz | used: List.delete(quiz.used, question.template)}
  end
end
