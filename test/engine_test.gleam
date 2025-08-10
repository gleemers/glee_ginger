import gleam/dict
import gleeunit
import gleeunit/should
import templating.{TemplateEngine, clear_cache, new_engine}

pub fn main() {
  gleeunit.main()
}

pub fn new_engine_test() {
  let engine = new_engine("templates")

  engine.template_dir
  |> should.equal("templates")

  engine.cache
  |> dict.size()
  |> should.equal(0)
}

pub fn clear_cache_test() {
  let engine = new_engine("templates")
  let engine_with_cache =
    TemplateEngine(
      template_dir: engine.template_dir,
      cache: dict.from_list([#("test", "content")]),
    )

  engine_with_cache.cache
  |> dict.size()
  |> should.equal(1)

  let cleared_engine = clear_cache(engine_with_cache)

  cleared_engine.cache
  |> dict.size()
  |> should.equal(0)

  cleared_engine.template_dir
  |> should.equal("templates")
}
