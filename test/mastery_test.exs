defmodule MasteryTest do
  use ExUnit.Case, async: false
  use QuizBuilders

  alias Mastery.Examples.Math
  alias Mastery.Boundary.QuizSession
  alias MasteryPersistence.Response

  # -- Tests

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MasteryPersistence.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(MasteryPersistence.Repo, {:shared, self()})

    add_1_to_2 = [
      template_fields(generators: addition_generators([1], [2]))
    ]

    assert "" !=
             ExUnit.CaptureLog.capture_log(fn ->
               :ok = start_quiz(add_1_to_2)
             end)

    :ok
  end

  test "Take a quiz, manage lifecyle and persist responses" do
    session = take_quiz("foo@bar")
    select_question(session)

    assert give_wrong_answer(session) == {"1 + 2", false}
    assert give_right_answer(session) == {"1 + 2", true}
    assert response_count() == 2

    assert give_right_answer(session) == :finished

    assert QuizSession.active_sessions_for(Math.quiz_fields().title) == []
  end

  test "Take a quiz, manage lifecyle and persist responses in memory" do
    session = take_quiz("foo@bar")
    select_question(session)

    {:ok, agent} = Agent.start_link(fn -> [] end)

    memory_store = fn response, in_transaction ->
      Agent.update(agent, fn rs -> [response | rs] end)
      in_transaction.(response)
    end

    assert give_wrong_answer(session, persistence_fn: memory_store) == {"1 + 2", false}
    assert give_right_answer(session, persistence_fn: memory_store) == {"1 + 2", true}
    assert length(Agent.get(agent, & &1)) == 2

    assert give_right_answer(session, persistence_fn: memory_store) == :finished

    assert QuizSession.active_sessions_for(Math.quiz_fields().title) == []
  end

  # -- Private

  defp response_count() do
    MasteryPersistence.Repo.aggregate(Response, :count, :id)
  end

  defp start_quiz(fields) do
    now = DateTime.utc_now()
    ending = DateTime.add(now, 60)
    Mastery.schedule_quiz(Math.quiz_fields(), fields, now, ending, notify_pid: nil)
  end

  defp take_quiz(email) do
    Mastery.take_quiz(Math.quiz().title, email)
  end

  defp select_question(session) do
    assert {:ok, "1 + 2"} = Mastery.select_question(session)
  end

  defp give_wrong_answer(session, opts \\ [persistence_fn: &MasteryPersistence.record_response/2]) do
    Mastery.answer_question(
      session,
      "wrong",
      opts
    )
  end

  defp give_right_answer(session, opts \\ [persistence_fn: &MasteryPersistence.record_response/2]) do
    Mastery.answer_question(
      session,
      "3",
      opts
    )
  end
end
