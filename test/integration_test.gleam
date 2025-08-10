import gleam/dict
import gleam/io
import gleam/string
import gleeunit
import gleeunit/should
import templating.{
  from_string, new_context, render, render_with_loops, set_list, set_variable,
}

pub fn main() {
  gleeunit.main()
}

pub fn integration_simple_test() {
  let template = from_string("Hello {{ name }}!")
  let context = dict.from_list([#("name", "World")])

  case render(template, context) {
    Ok(result) -> {
      result |> should.equal("Hello World!")
      io.println("Simple template test passed: " <> result)
    }
    Error(_) -> should.be_true(False)
  }
}

pub fn integration_complex_test() {
  let template =
    from_string(
      "
Welcome {{ user }}!

Your tasks:
{% for task in tasks %}
- {{ task }}
{% endfor %}

Total: {{ count }} tasks
",
    )

  let context =
    new_context()
    |> set_variable("user", "Alice")
    |> set_variable("count", "2")
    |> set_list("tasks", ["Buy milk", "Walk dog"])

  case render_with_loops(template, context) {
    Ok(result) -> {
      io.println("Complex template test passed:")
      io.println(result)
      should.be_true(result |> contains("Alice"))
      should.be_true(result |> contains("Buy milk"))
      should.be_true(result |> contains("Walk dog"))
      should.be_true(result |> contains("2 tasks"))
    }
    Error(_) -> should.be_true(False)
  }
}

pub fn integration_empty_list_test() {
  let template =
    from_string("Items: {% for item in items %}{{ item }} {% endfor %}(end)")
  let context = new_context() |> set_list("items", [])

  case render_with_loops(template, context) {
    Ok(result) -> {
      result |> should.equal("Items: (end)")
      io.println("Empty list test passed: " <> result)
    }
    Error(_) -> should.be_true(False)
  }
}

pub fn integration_missing_variable_test() {
  let template = from_string("Hello {{ missing }}!")
  let context = dict.new()

  case render(template, context) {
    Ok(result) -> {
      result |> should.equal("Hello {{ missing }}!")
      io.println("Missing variable test passed: " <> result)
    }
    Error(_) -> should.be_true(False)
  }
}

fn contains(haystack: String, needle: String) -> Bool {
  case haystack {
    _ -> {
      string.contains(haystack, needle)
    }
  }
}
