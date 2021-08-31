defmodule MasteryPersistenceTest do
  use ExUnit.Case, async: true

  alias MasteryPersistence.{Repo, Response}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    response = %{
      quiz_title: :simple_addition,
      template_name: :single_digit_addition,
      question: "3 + 0",
      email: "bar@foo",
      answer: "3",
      correct: true,
      timestamp: DateTime.utc_now()
    }

    {:ok, %{response: response}}
  end

  test "Responses are recorded", %{response: response} do
    assert Repo.aggregate(Response, :count, :id) == 0
    assert :ok = MasteryPersistence.record_response(response, fn _r -> :ok end)
    assert Repo.all(Response) |> Enum.map(fn r -> r.email end) == [response.email]
  end

  test "A function can be run in the saving transaction", %{response: response} do
    assert response.answer == MasteryPersistence.record_response(response, fn r -> r.answer end)
  end

  test "An error in the function rolls back the save", %{response: response} do
    assert Repo.aggregate(Response, :count, :id) == 0
    assert_raise RuntimeError, fn ->
      MasteryPersistence.record_response(response, fn _r -> raise "error" end)
    end
    assert Repo.aggregate(Response, :count, :id) == 0
  end

  test "Simple reporting", %{response: response} do
    MasteryPersistence.record_response(response, fn _r -> :ok end)
    MasteryPersistence.record_response(response, fn _r -> :ok end)

    response
    |> Map.put(:email, "other")
    |> MasteryPersistence.record_response(fn _r -> :ok end)

    assert MasteryPersistence.report(response.quiz_title)== %{
      response.email => 2,
      "other" => 1
    }
  end
end
