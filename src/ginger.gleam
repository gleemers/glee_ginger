import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleam/regexp.{type Match, type Regexp}
import gleam/result
import gleam/string
import simplifile

pub type Template {
  Template(content: String)
}

pub type TemplateContext {
  TemplateContext(
    variables: Dict(String, String),
    lists: Dict(String, List(String)),
  )
}

pub type TemplateEngine {
  TemplateEngine(template_dir: String, cache: Dict(String, String))
}

pub type TemplateError {
  IoError(String)
  RegexError(String)
}

pub fn from_file(path: String) -> Result(Template, TemplateError) {
  case simplifile.read(path) {
    Ok(content) -> Ok(Template(content))
    Error(_) -> Error(IoError("Failed to read file: " <> path))
  }
}

pub fn from_string(content: String) -> Template {
  Template(content)
}

pub fn render(
  template: Template,
  context: Dict(String, String),
) -> Result(String, TemplateError) {
  let Template(content) = template
  render_variables(content, context)
}

pub fn render_with_loops(
  template: Template,
  context: TemplateContext,
) -> Result(String, TemplateError) {
  let Template(content) = template

  use looped_content <- result.try(process_loops(content, context))
  render_variables(looped_content, context.variables)
}

fn render_variables(
  content: String,
  context: Dict(String, String),
) -> Result(String, TemplateError) {
  case regexp.from_string("\\{\\%\\s*(\\w+)\\s*\\%\\}") {
    Ok(re) -> {
      let matches = regexp.scan(with: re, content: content)
      let result = replace_matches(content, matches, context)
      Ok(result)
    }
    Error(_) -> Error(RegexError("Failed to compile variable regex"))
  }
}

fn replace_matches(
  content: String,
  matches: List(Match),
  context: Dict(String, String),
) -> String {
  list.fold(matches, content, fn(acc, match) {
    case match.submatches {
      [Some(var_name)] -> {
        case dict.get(context, var_name) {
          Ok(value) -> string.replace(acc, match.content, value)
          Error(_) -> acc
        }
      }
      _ -> acc
    }
  })
}

fn process_loops(
  content: String,
  context: TemplateContext,
) -> Result(String, TemplateError) {
  case
    regexp.from_string(
      "\\{%\\s*for\\s+(\\w+)\\s+in\\s+(\\w+)\\s*%\\}([\\s\\S]*?)\\{%\\s*endfor\\s*%\\}",
    )
  {
    Ok(loop_re) -> {
      process_loops_recursive(content, context, loop_re)
    }
    Error(_) -> Error(RegexError("Failed to compile loop regex"))
  }
}

fn process_loops_recursive(
  content: String,
  context: TemplateContext,
  loop_re: Regexp,
) -> Result(String, TemplateError) {
  case regexp.scan(with: loop_re, content: content) {
    [] -> Ok(content)
    [first_match, ..] -> {
      case first_match.submatches {
        [Some(var_name), Some(list_name), Some(loop_body)] -> {
          let loop_result = case dict.get(context.lists, list_name) {
            Ok(items) -> {
              list.fold(items, "", fn(acc, item) {
                let item_content =
                  replace_loop_variable(loop_body, var_name, item)
                acc <> item_content
              })
            }
            Error(_) -> ""
          }

          let new_content =
            string.replace(content, first_match.content, loop_result)
          process_loops_recursive(new_content, context, loop_re)
        }
        _ -> Ok(content)
      }
    }
  }
}

fn replace_loop_variable(
  template: String,
  var_name: String,
  value: String,
) -> String {
  let target = "{{ " <> var_name <> " }}"
  let target_no_spaces = "{{" <> var_name <> "}}"

  template
  |> string.replace(target, value)
  |> string.replace(target_no_spaces, value)
}

pub fn new_context() -> TemplateContext {
  TemplateContext(variables: dict.new(), lists: dict.new())
}

pub fn set_variable(
  context: TemplateContext,
  key: String,
  value: String,
) -> TemplateContext {
  TemplateContext(
    variables: dict.insert(context.variables, key, value),
    lists: context.lists,
  )
}

pub fn set_list(
  context: TemplateContext,
  key: String,
  items: List(String),
) -> TemplateContext {
  TemplateContext(
    variables: context.variables,
    lists: dict.insert(context.lists, key, items),
  )
}

pub fn new_engine(template_dir: String) -> TemplateEngine {
  TemplateEngine(template_dir: template_dir, cache: dict.new())
}

pub fn load_template_content(
  engine: TemplateEngine,
  name: String,
) -> Result(#(TemplateEngine, String), TemplateError) {
  case dict.get(engine.cache, name) {
    Ok(content) -> Ok(#(engine, content))
    Error(_) -> {
      let template_path = engine.template_dir <> "/" <> name <> ".html"
      case simplifile.read(template_path) {
        Ok(content) -> {
          let new_cache = dict.insert(engine.cache, name, content)
          let new_engine = TemplateEngine(..engine, cache: new_cache)
          Ok(#(new_engine, content))
        }
        Error(_) -> Error(IoError("Failed to load template: " <> template_path))
      }
    }
  }
}

pub fn render_template(
  engine: TemplateEngine,
  template_name: String,
  context: TemplateContext,
) -> Result(#(TemplateEngine, String), TemplateError) {
  use #(new_engine, content) <- result.try(load_template_content(
    engine,
    template_name,
  ))
  let template = Template(content)
  use rendered <- result.try(render_with_loops(template, context))
  Ok(#(new_engine, rendered))
}

pub fn render_simple_template(
  engine: TemplateEngine,
  template_name: String,
  context: Dict(String, String),
) -> Result(#(TemplateEngine, String), TemplateError) {
  use #(new_engine, content) <- result.try(load_template_content(
    engine,
    template_name,
  ))
  let template = Template(content)
  use rendered <- result.try(render(template, context))
  Ok(#(new_engine, rendered))
}

pub fn clear_cache(engine: TemplateEngine) -> TemplateEngine {
  TemplateEngine(..engine, cache: dict.new())
}

pub fn context_from_list(variables: List(#(String, String))) -> TemplateContext {
  let var_dict = dict.from_list(variables)
  TemplateContext(variables: var_dict, lists: dict.new())
}
