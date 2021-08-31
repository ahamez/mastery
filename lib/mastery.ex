defmodule Mastery do
  alias Mastery.Boundary.{QuizManager, QuizSession, Proctor}
  alias Mastery.Boundary.{QuizValidator, TemplateValidator}
  alias Mastery.Core.Quiz

  @default_persistence_fn Application.get_env(:mastery, :persistence_fn)

  def build_quiz(fields) do
    with :ok <- QuizValidator.check(fields),
         :ok <- QuizManager.build_quiz(QuizManager, fields) do
      :ok
    else
      error -> error
    end
  end

  def add_template(title, fields) do
    with :ok <- TemplateValidator.check(fields),
         :ok <- QuizManager.add_template(QuizManager, title, fields) do
      :ok
    else
      error -> error
    end
  end

  def take_quiz(title, email) do
    with %Quiz{} = quiz <- QuizManager.lookup_quiz_by_title(QuizManager, title),
         {:ok, _} <- QuizSession.take_quiz(quiz, email) do
      {title, email}
    else
      error -> error
    end
  end

  def select_question(quiz_title) do
    QuizSession.select_question(quiz_title)
  end

  def answer_question(quiz_title, answer, options \\ []) do
    persistence_fn = Keyword.get(options, :persistence_fn, @default_persistence_fn)

    QuizSession.answer_question(quiz_title, answer, persistence_fn)
  end

  def schedule_quiz(quiz_fields, templates, start_at, end_at, opts) do
    schedule_quiz_opts = Keyword.take(opts, [:notify_pid])

    with :ok <- QuizValidator.check(quiz_fields),
         true <- Enum.all?(templates, fn t -> :ok == TemplateValidator.check(t) end),
         :ok <-
           Proctor.schedule_quiz(quiz_fields, templates, start_at, end_at, schedule_quiz_opts) do
      :ok
    else
      error -> error
    end
  end
end
