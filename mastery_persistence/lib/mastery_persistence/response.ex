defmodule MasteryPersistence.Response do
  use Ecto.Schema

  @mastery_fields ~w[
    quiz_title
    template_name
    question
    email
    answer
    correct
  ]a

  @timestamps ~w[
    inserted_at
    updated_at
  ]a

  schema "responses" do
    field(:quiz_title, :string)
    field(:template_name, :string)
    field(:question, :string)
    field(:email, :string)
    field(:answer, :string)
    field(:correct, :boolean)

    timestamps()
  end

  def changeset(fields) do
    import Ecto.Changeset

    %__MODULE__{}
    |> cast(fields, @mastery_fields ++ @timestamps)
    |> validate_required(@mastery_fields ++ @timestamps)
  end
end
