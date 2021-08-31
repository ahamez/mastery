defmodule Mastery.Boundary.QuizSession do
  use GenServer

  alias Mastery.Core.{Quiz, Response}

  # -- Initialization

  @spec init({Quiz.t(), String.t()}) :: {:ok, {Quiz.t(), String.t()}}
  @impl true
  def init({quiz, email}) do
    {:ok, {quiz, email}}
  end

  def child_spec({quiz, email}) do
    %{
      id: {__MODULE__, {quiz.title, email}},
      start: {__MODULE__, :start_link, [{quiz, email}]},
      restart: :temporary
    }
  end

  def start_link({quiz, email}) do
    GenServer.start_link(__MODULE__, {quiz, email}, name: via({quiz.title, email}))
  end

  # -- API

  def take_quiz(quiz, email) do
    DynamicSupervisor.start_child(Mastery.Supervisor.QuizSession, {__MODULE__, {quiz, email}})
  end

  def select_question({title, email}) do
    GenServer.call(via({title, email}), :select_question)
  end

  def answer_question({title, email}, answer, persistence_fn) do
    GenServer.call(via({title, email}), {:answer_question, answer, persistence_fn})
  end

  def active_sessions_for(quiz_title) do
    Mastery.Supervisor.QuizSession
    |> DynamicSupervisor.which_children()
    |> Enum.filter(&child_pid?/1)
    |> Enum.flat_map(&active_sessions(&1, quiz_title))
  end

  def end_sessions(names) do
    Enum.each(names, fn name -> GenServer.stop(via(name)) end)
  end

  # -- GenServer callbacks

  @impl true
  def handle_call(:select_question, _from, {quiz, email}) do
    quiz = Quiz.select_question(quiz)

    if quiz do
      {:reply, {:ok, quiz.current_question.asked}, {quiz, email}}
    else
      {:reply, {:error, :empty_quiz}, {quiz, email}}
    end
  end

  @impl true
  def handle_call({:answer_question, answer, persistence_fn}, _from, {quiz, email}) do
    # Will be called by the persistence layer.
    # Thus, if a failure occurs while answering a question, the persistence layer
    # will be able to roll back.
    in_transaction_fn = fn response ->
      quiz
      |> Quiz.answer_question(response)
      |> Quiz.select_question()
    end

    quiz
    |> Response.new(email, answer)
    |> persistence_fn.(in_transaction_fn)
    |> maybe_finish(email)
  end

  # -- Private

  defp via(name) do
    {:via, Registry, {Mastery.Registry.QuizSession, name}}
  end

  defp maybe_finish(nil, _email) do
    {:stop, :normal, :finished, nil}
  end

  defp maybe_finish(quiz, email) do
    {:reply, {quiz.current_question.asked, quiz.last_response.correct}, {quiz, email}}
  end

  defp child_pid?({:undefined, pid, :worker, [__MODULE__]}) when is_pid(pid) do
    true
  end

  defp child_pid?(_child), do: false

  defp active_sessions({:undefined, pid, :worker, [__MODULE__]}, title) do
    Mastery.Registry.QuizSession
    |> Registry.keys(pid)
    |> Enum.filter(fn {quiz_title, _email} -> quiz_title == title end)
  end
end
