defmodule Mastery.Core.ResponseTest do
  use ExUnit.Case
  use QuizBuilders

  defp mk_quiz() do
    fields = template_fields(generators: %{left: [1], right: [2]})

    build_quiz()
    |> Quiz.add_template(fields)
    |> Quiz.select_question()
  end

  defp mk_response(answer) do
    Response.new(mk_quiz(), "foo@bar", answer)
  end

  defp right(context) do
    {:ok, Map.put(context, :right, mk_response("3"))}
  end

  defp wrong(context) do
    {:ok, Map.put(context, :wrong, mk_response("1"))}
  end

  describe "A right response and a wrong response" do
    setup [:right, :wrong]

    test "Build responses checks answers", %{right: right, wrong: wrong} do
      assert right.correct
      refute wrong.correct
    end

    test "A timestamps is added at build time", %{right: response} do
      assert %DateTime{} = response.timestamp
      assert response.timestamp < DateTime.utc_now()
    end
  end
end
