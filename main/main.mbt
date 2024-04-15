fn main {
  let input =
    #| {
    #|  "items": [1],
    #|  "nested": {
    #|    "items": [1, 2, 3, 4.5]
    #|  },
    #|  "items2": [{"a": 1}, {"b": 2}],
    #|  "next": null
    #| }
  let parsed = @lib.parse(input).unwrap()
  debug(parsed)
  println(parsed.stringify())
  println(parsed.stringify(~spaces=2, ~newline=true))
}
