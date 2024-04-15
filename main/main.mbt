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
  debug(parsed) // debuggable
  println(parsed.stringify())
  //=> {items:[1],nested:{items:[1,2,3,4.5]},items2:[{a:1},{b:2}],next:null}

  // readable json like JSON.stringify(obj, null, 2)
  println(parsed.stringify(~spaces=2, ~newline=true))

  // build json tree
  let data = @lib.JSONValue::Object(
    List::[
      ("key", @lib.JSONValue::String("val")),
      ("items", @lib.JSONValue::Array(List::[@lib.JSONValue::IntNumber(1)])),
    ],
  )
  // you can stringify
  println(data.stringify())

  // handle parse error
  match @lib.parse("{}}") {
    Err(err) => debug(err)
    _ => println("unreachable")
  }
}
