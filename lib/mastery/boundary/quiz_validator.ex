defmodule Mastery.Boundary.QuizValidator do
  import Mastery.Boundary.Validator

  def check(fields) when is_map(fields) do
    []
    |> require(fields, :title, &validate_title/1)
    |> optional(fields, :mastery, &validate_mastery/1)
  end

  def validate_title(title) when is_binary(title) do
    check(String.match?(title, ~r{\S}), {:error, "can't be blank"})
  end

  def validate_title(_) do
    {:error, "must be a string"}
  end

  def validate_mastery(mastery) when is_integer(mastery) do
    check(mastery >= 1, {:error, "must be greater than zero"})
  end

  def validate_mastery(_) do
    {:error, "must be a positive integer"}
  end
end
