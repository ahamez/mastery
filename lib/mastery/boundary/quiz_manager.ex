defmodule Mastery.Boundary.QuizManager do
  alias Mastery.Core.{Quiz, Template}

  require Logger

  use GenServer

  # -- Initialization

  def start_link(options \\ []) do
    Logger.info("#{__MODULE__} options: #{inspect(options)}")

    GenServer.start_link(__MODULE__, %{}, options)
  end

  @spec init(map()) :: {:ok, map()}
  @impl true
  def init(quizzes) when is_map(quizzes) do
    {:ok, quizzes}
  end

  # -- API

  def build_quiz(server \\ __MODULE__, quiz_fields) do
    GenServer.call(server, {:build_quiz, quiz_fields})
  end

  @spec add_template(GenServer.server(), String.t(), Template.fields()) :: term()
  def add_template(server \\ __MODULE__, quiz_title, template_fields) do
    GenServer.call(server, {:add_template, quiz_title, template_fields})
  end

  def lookup_quiz_by_title(server \\ __MODULE__, quiz_title) do
    GenServer.call(server, {:lookup_quiz_by_title, quiz_title})
  end

  def remove_quiz(server \\ __MODULE__, quiz_title) do
    GenServer.call(server, {:remove_quiz, quiz_title})
  end

  # -- GenServer callbacks

  @impl true
  def handle_call({:build_quiz, quiz_fields}, _from, quizzes) do
    quiz = Quiz.new(quiz_fields)
    new_quizzes = Map.put(quizzes, quiz.title, quiz)

    {:reply, :ok, new_quizzes}
  end

  @impl true
  def handle_call({:add_template, quiz_title, template_fields}, _from, quizzes) do
    new_quizzes =
      Map.update!(quizzes, quiz_title, fn quiz ->
        Quiz.add_template(quiz, template_fields)
      end)

    {:reply, :ok, new_quizzes}
  end

  @impl true
  def handle_call({:lookup_quiz_by_title, quiz_title}, _from, quizzes) do
    {:reply, quizzes[quiz_title], quizzes}
  end

  @impl true
  def handle_call({:remove_quiz, quiz_title}, _from, quizzes) do
    new_quizzes = Map.delete(quizzes, quiz_title)

    {:reply, quiz_title, new_quizzes}
  end
end
