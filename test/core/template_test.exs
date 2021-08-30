defmodule Mastery.Core.TemplateTest do
  use ExUnit.Case
  use QuizBuilders

  test "building compiles the raw template" do
    fields = template_fields()
    assert is_nil(Keyword.get(fields, :compiled))

    template = Template.new(fields)
    refute is_nil(template.compiled)
  end
end
