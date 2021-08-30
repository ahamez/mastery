defmodule Mastery.Boundary.Proctor do
  use GenServer

  require Logger

  alias Mastery.Boundary.{QuizManager, QuizSession}
  alias Mastery.Core.Template

  # -- Types

  @type quiz_map() :: %{
          fields: map() | keyword(),
          start_at: Calendar.datetime(),
          end_at: Calendar.datetime(),
          templates: %{Template.category() => [Template.t()]}
        }

  # -- Initialization

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  @impl true
  def init(quizzes) do
    {:ok, quizzes}
  end

  # -- API

  @spec start_quiz(quiz_map(), DateTime.t()) :: :ok | :error
  def start_quiz(quiz, now) do
    Logger.info("Starting quiz #{quiz.fields.title}")

    QuizManager.build_quiz(quiz.fields)

    Enum.each(quiz.templates, &QuizManager.add_template(quiz.fields.title, &1))

    try do
      timeout = DateTime.diff(quiz.end_at, now, :millisecond)
      _ = Process.send_after(self(), {:end_quiz, quiz.fields.title}, timeout)
      :ok
    rescue
      _ -> :error
    end
  end

  def schedule_quiz(server \\ __MODULE__, quiz_fields, templates, start_at, end_at) do
    Logger.info("Will schedule quiz #{inspect(quiz_fields)}")

    quiz = %{
      fields: quiz_fields,
      templates: templates,
      start_at: start_at,
      end_at: end_at
    }

    GenServer.call(server, {:schedule_quiz, quiz})
  end

  # -- GenServer callbacks

  @impl true
  def handle_call({:schedule_quiz, quiz}, _from, quizzes) do
    now = DateTime.utc_now()

    [quiz | quizzes]
    |> sort_quizzes_by_start_time()
    |> start_quizzes(now)
    |> build_reply_with_timeout({:reply, :ok}, now)
  end

  @impl true
  def handle_info(:timeout, quizzes) do
    now = DateTime.utc_now()
    remaining_quizzes = start_quizzes(quizzes, now)

    {:noreply, remaining_quizzes}
  end

  @impl true
  def handle_info({:end_quiz, title}, quizzes) do
    Logger.info("Stopping quiz #{title}")

    title
    |> QuizManager.remove_quiz()
    |> QuizSession.active_sessions_for()
    |> QuizSession.end_sessions()

    Logger.info("Stopped quiz #{title}")

    handle_info(:timeout, quizzes)
  end

  # -- Private

  defp build_reply_with_timeout(quizzes, reply, now) do
    append_to_state = fn state, quizzes -> Tuple.append(state, quizzes) end

    reply
    |> append_to_state.(quizzes)
    |> maybe_append_timeout(quizzes, now)
  end

  defp maybe_append_timeout(reply, [], _now), do: reply

  defp maybe_append_timeout(reply, [quiz | _], now) do
    timeout = DateTime.diff(quiz.start_at, now, :millisecond)

    Tuple.append(reply, timeout)
  end

  defp start_quizzes(quizzes, now) do
    {ready, not_ready} =
      Enum.split_while(quizzes, fn quiz ->
        date_time_less_than_or_equal?(quiz.start_at, now)
      end)

    Enum.each(ready, &start_quiz(&1, now))

    not_ready
  end

  defp sort_quizzes_by_start_time(quizzes) do
    Enum.sort(
      quizzes,
      fn lhs, rhs -> date_time_less_than_or_equal?(lhs.start, rhs.start_at) end
    )
  end

  defp date_time_less_than_or_equal?(lhs, rhs) do
    cmp = DateTime.compare(lhs, rhs)

    cmp == :lt or cmp == :eq
  end
end
