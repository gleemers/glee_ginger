import gleam/dict
import gleeunit
import gleeunit/should
import templating.{
  Template, context_from_list, from_string, new_context, render,
  render_with_loops, set_list, set_variable,
}

pub fn main() {
  gleeunit.main()
}

pub fn render_simple_variable_test() {
  let template = from_string("Hello {{ name }}!")
  let context = dict.from_list([#("name", "Alice")])

  render(template, context)
  |> should.be_ok()
  |> should.equal("Hello Alice!")
}

pub fn render_multiple_variables_test() {
  let template = from_string("Hello {{ name }}, you are {{ age }} years old!")
  let context = dict.from_list([#("name", "Bob"), #("age", "25")])

  render(template, context)
  |> should.be_ok()
  |> should.equal("Hello Bob, you are 25 years old!")
}

pub fn render_missing_variable_test() {
  let template = from_string("Hello {{ name }}!")
  let context = dict.new()

  render(template, context)
  |> should.be_ok()
  |> should.equal("Hello {{ name }}!")
}

pub fn render_variable_with_whitespace_test() {
  let template = from_string("Hello {{  name  }}!")
  let context = dict.from_list([#("name", "Charlie")])

  render(template, context)
  |> should.be_ok()
  |> should.equal("Hello Charlie!")
}

pub fn render_simple_loop_test() {
  let template =
    from_string("Items: {% for item in items %}{{ item }} {% endfor %}")
  let context =
    new_context()
    |> set_list("items", ["apple", "banana", "cherry"])

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("Items: apple banana cherry ")
}

pub fn render_loop_with_variables_test() {
  let template =
    from_string(
      "Hello {{ name }}! Items: {% for item in items %}{{ item }} {% endfor %}",
    )
  let context =
    new_context()
    |> set_variable("name", "Dave")
    |> set_list("items", ["red", "green", "blue"])

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("Hello Dave! Items: red green blue ")
}

pub fn render_empty_loop_test() {
  let template =
    from_string("Items: {% for item in items %}{{ item }} {% endfor %}Done.")
  let context =
    new_context()
    |> set_list("items", [])

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("Items: Done.")
}

pub fn render_missing_loop_list_test() {
  let template =
    from_string("Items: {% for item in missing %}{{ item }} {% endfor %}Done.")
  let context = new_context()

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("Items: Done.")
}

pub fn render_nested_loop_variables_test() {
  let template =
    from_string(
      "{% for item in items %}- {{ item }} for {{ user }}\\n{% endfor %}",
    )
  let context =
    new_context()
    |> set_variable("user", "Emma")
    |> set_list("items", ["task1", "task2"])

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("- task1 for Emma\\n- task2 for Emma\\n")
}

pub fn new_context_test() {
  let context = new_context()

  context.variables
  |> dict.size()
  |> should.equal(0)

  context.lists
  |> dict.size()
  |> should.equal(0)
}

pub fn set_variable_test() {
  let context =
    new_context()
    |> set_variable("name", "Frank")
    |> set_variable("age", "30")

  context.variables
  |> dict.get("name")
  |> should.be_ok()
  |> should.equal("Frank")

  context.variables
  |> dict.get("age")
  |> should.be_ok()
  |> should.equal("30")
}

pub fn set_list_test() {
  let context =
    new_context()
    |> set_list("colors", ["red", "green", "blue"])
    |> set_list("numbers", ["1", "2", "3"])

  context.lists
  |> dict.get("colors")
  |> should.be_ok()
  |> should.equal(["red", "green", "blue"])

  context.lists
  |> dict.get("numbers")
  |> should.be_ok()
  |> should.equal(["1", "2", "3"])
}

pub fn context_from_list_test() {
  let context = context_from_list([#("name", "Grace"), #("city", "Portland")])

  context.variables
  |> dict.get("name")
  |> should.be_ok()
  |> should.equal("Grace")

  context.variables
  |> dict.get("city")
  |> should.be_ok()
  |> should.equal("Portland")

  context.lists
  |> dict.size()
  |> should.equal(0)
}

pub fn render_complex_template_test() {
  let template_content =
    "
# Welcome {{ user }}!

## Your Items:
{% for item in items %}
- {{ item }}
{% endfor %}

## Summary:
You have {{ count }} items.
"

  let template = from_string(template_content)
  let context =
    new_context()
    |> set_variable("user", "Henry")
    |> set_variable("count", "3")
    |> set_list("items", ["laptop", "mouse", "keyboard"])

  let expected =
    "
# Welcome Henry!

## Your Items:

- laptop

- mouse

- keyboard


## Summary:
You have 3 items.
"

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal(expected)
}

pub fn render_multiple_loops_test() {
  let template =
    from_string(
      "Colors: {% for color in colors %}{{ color }} {% endfor %}Numbers: {% for num in numbers %}{{ num }} {% endfor %}",
    )
  let context =
    new_context()
    |> set_list("colors", ["red", "blue"])
    |> set_list("numbers", ["1", "2", "3"])

  render_with_loops(template, context)
  |> should.be_ok()
  |> should.equal("Colors: red blue Numbers: 1 2 3 ")
}

pub fn render_no_variables_test() {
  let template = from_string("This is a plain template with no variables.")
  let context = dict.new()

  render(template, context)
  |> should.be_ok()
  |> should.equal("This is a plain template with no variables.")
}

pub fn render_empty_template_test() {
  let template = from_string("")
  let context = dict.new()

  render(template, context)
  |> should.be_ok()
  |> should.equal("")
}

pub fn render_only_variables_test() {
  let template = from_string("{{ a }}{{ b }}{{ c }}")
  let context = dict.from_list([#("a", "X"), #("b", "Y"), #("c", "Z")])

  render(template, context)
  |> should.be_ok()
  |> should.equal("XYZ")
}

pub fn render_malformed_variable_test() {
  let template = from_string("Hello {{ name and {{ age }}!")
  let context = dict.from_list([#("name", "Ivan"), #("age", "40")])

  render(template, context)
  |> should.be_ok()
  |> should.equal("Hello {{ name and 40!")
}

pub fn from_string_test() {
  let template = from_string("Hello {{ world }}!")

  case template {
    Template(content) -> content |> should.equal("Hello {{ world }}!")
  }
}
