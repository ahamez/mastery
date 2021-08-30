defmodule Mastery.Core.Response do
  @type t() :: %__MODULE__{}

  defstruct [
    :quiz_title,
    :template_name,
    :question,
    :email,
    :answer,
    :correct,
    :timestamp
  ]

  @spec new(Mastery.Core.Quiz.t(), String.t(), any()) :: t()
  def new(quiz, email, answer) do
    question = quiz.current_question
    template = question.template

    %__MODULE__{
      quiz_title: quiz.title,
      template_name: template.name,
      question: question.asked,
      email: email,
      answer: answer,
      correct: template.checker.(question.substitutions, answer),
      timestamp: DateTime.utc_now()
    }
  end
end
