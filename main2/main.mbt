fn main {
  let input = "null"
  let parsed = @lib.tokenize(input)
  debug(parsed)
  // println(parsed.stringify())
  // println(parsed.stringify(~spaces=2, ~newline=true))
}
