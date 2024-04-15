# mizchi/json

hobby json parser (yet)

```bash
$ moon add mizchi/json
```

## Usage

```rust
fn main {
  let input =
    #| {
    #|  "items": [1],
    #|  "nested": {
    #|    "items": [1, 2, 3, 4.5],
    #|  },
    #|  "items2": [{"a": 1}, {"b": 2}],
    #|  "next": null
    #| }
  let parsed = @lib.parse(input).unwrap()

  debug(parsed)
  // => Object(List::[("items", Array(List::[IntNumber(1)])), ("nested", Object(List::[("items", Array(List::[IntNumber(1), IntNumber(2), IntNumber(3), DoubleNumber(4.5)]))])), ("items2", Array(List::[Object(List::[("a", IntNumber(1))]), Object(List::[("b", IntNumber(2))])])), ("next", Null)])

  // stringify
  println(parsed.stringify())
  // readable stringify
  println(parsed.stringify(~spaces=2, ~newline=true))
}
```

## TODO

- [ ] Valid error message
- [ ] parse expression `1`
- [ ] Mutation

## LICENSE

MIT