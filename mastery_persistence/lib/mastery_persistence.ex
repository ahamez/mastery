defmodule MasteryPersistence do
  import Ecto.Query, only: [from: 2]
  alias MasteryPersistence.{Repo, Response}

  def record_response(response) do
    {:ok, result} =
      Repo.transaction(fn ->
        %{
          quiz_title: to_string(response.quiz_title),
          template_name: to_string(response.template_name),
          question: response.question,
          email: response.email,
          answer: response.answer,
          correct: response.correct,
          inserted_at: response.timestamp,
          updated_at: response.timestamp
        }
        |> Response.changeset()
        |> Repo.insert!()

        :ok
      end)

    result
  end

  def report(quiz_title) do
    quiz_title = to_string(quiz_title)

    query =
      from(r in Response,
        select: {r.email, count(r.id)},
        where: r.quiz_title == ^quiz_title,
        group_by: [r.quiz_title, r.email]
      )

    query
    |> Repo.all()
    |> Enum.into(Map.new())
  end
end
