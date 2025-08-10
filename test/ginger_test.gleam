import engine_test
import gleam/io
import templating_test

pub fn main() {
  io.println("Running templating tests...")

  templating_test.main()

  engine_test.main()

  io.println("All tests completed!")
}
