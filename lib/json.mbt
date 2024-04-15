let syntax_tokens: Array[Char] = [
  '{',
  '}',
  '[',
  ']',
  '"',
  ':',
  ',',
  ' ',
  '\n'
]

pub enum JSONValue {
  String(String)
  IntNumber(Int) // TODO: Int
  DoubleNumber(Double) // TODO: Int
  Object(List[(String, JSONValue)])
  Array(List[JSONValue])
  Null
} derive(Debug, Eq)

pub enum ParseError {
  OutOfRange
  ExpectEOF
  ExpectToken(String)
  Message(String)
  // ChildParseError(ParseError)
} derive(Debug, Eq)

pub fn tokenize(input: String) -> List[String] {
  let len = input.length()

  let mut in_string_literal = false
  let tokens: @vec.Vec[String] = @vec.Vec::[]
  let buf: @vec.Vec[Char] = @vec.Vec::[]
  // TODO: use bytes instead of chars for speed
  // let bytes = input.to_bytes()
  fn eat() {
    if buf.length() > 0 {
      let mut s = ""
      buf.iter(fn (c) {
        s += c.to_string()
      })
      tokens.push(s)
      buf.clear()
    }
  }
  for i = 0; i < len; i = i + 1 {
    let char = input.get(i)
    let is_syntax_token = syntax_tokens.contains(char)
    if in_string_literal {
      // end
      if char == '"' {
        buf.push(char)
        eat()
        // tokens.push("\"")
        in_string_literal = false
        // println("leave literal mode")
        continue
      } 
      buf.push(char)
      continue
    }
    if is_syntax_token {
      if buf.length() > 0 {
        eat()
      }
      if char == ' ' || char == '\n' {
        continue
      }
      if char == '"' {
        in_string_literal = true
        buf.push(char)
      } else {
        tokens.push(char.to_string())
        buf.clear()
      }
      continue
    }
    buf.push(char)
  }
  return tokens.to_list()
}

pub fn stringify(self: JSONValue, ~depth: Int = 0, ~spaces: Int = 0, ~newline: Bool = false) -> String {
  // println("depth \(depth)")
  match self {
    JSONValue::String(s) => {
      return "\"\(s)\""
    }
    JSONValue::IntNumber(n) => {
      return n.to_string()
    }
    JSONValue::DoubleNumber(n) => {
      return n.to_string()
    }
    JSONValue::Array(a) => {
      let mut s = "[" + if newline { "\n" } else { "" }

      a.iteri(fn (i, v) {
        let suffix = if i==a.length()-1 { "" } else { "," } + if newline { "\n" } else { "" }
        s += String::make((depth + 1) * spaces, ' ') + stringify(v, ~depth=depth+1, ~spaces, ~newline) + suffix
      })
      s += String::make(depth*spaces, ' ') + "]"
      return s
    }
    JSONValue::Object(o) => {
      let mut s = "{" + if newline { "\n" } else { "" }
      let pad = if spaces > 0 { " " } else { "" }
      for i = 0; i < o.length(); i = i + 1 {
        let (k, v) = o.nth(i).unwrap()
        let is_last = i == o.length() - 1
        let last = if is_last { "" } else { "," } + if newline { "\n" } else { "" }
        let vr = v.stringify(~depth=depth + 1, ~spaces, ~newline)
        s += String::make((depth + 1) * spaces, ' ') + "\(k):\(pad)\(vr)\(last)"
      }
      s += String::make(depth * spaces, ' ') + "}"
      return s
    }
    JSONValue::Null => {
      return "null"
    }
  }
}

pub fn parse_literal(tokens: List[String], start: Int) -> Result[(JSONValue, Int), ParseError] {
  if (tokens.length() <= start) {
    return Err(ParseError::OutOfRange)
  }
  match tokens.nth(start) {
    None => {
      Err(ParseError::OutOfRange)
    }
    Some(expr) => {
      let first = expr.get(0)
      let last = expr.get(expr.length() - 1)
      if expr == "{" {
        match parse_object(tokens, start) {
          Ok((members, end)) => {
            return Ok((JSONValue::Object(members), end + 1))
          }
          Err(reason) => {
            return Err(reason)
          }
        }
      }
      if expr == "[" {
        match parse_array(tokens, start) {
          Ok((items, end)) => {
            return Ok((JSONValue::Array(items), end + 1))
          }
          Err(error) => {
            return Err(error)
          }
        }
      }
      if expr == "null" {
        return Ok((JSONValue::Null, start + 1))
      }

      // println("parse_literal \(start)")
      if first == '"' && last == '"' {
        let mut s = ""
        for i = 1; i < expr.length() - 1; i = i + 1 {
          s += expr.get(i).to_string()
        }
        // let value = expr.to_bytes().sub_string(1, expr.length() - 2)
        return Ok((JSONValue::String(s), start + 1))
      }
      let int = @strconv.parse_int(expr)
      if (int.is_ok()) {
        // println("int found")
        return Ok((JSONValue::IntNumber(int.unwrap()), start + 1))
      }

      let double = @strconv.parse_double(expr)
      if double.is_ok() {
        return Ok((JSONValue::DoubleNumber(double.unwrap()), start + 1))
      }
      Err(ParseError::ExpectToken(expr))
    }
  }
  // let expr = tokens.nth(start)
}

pub fn parse_object(tokens: List[String], start: Int) -> Result[(List[(String, JSONValue)], Int), ParseError] {
  match tokens.nth(start) {
    None => {
      return Err(ParseError::OutOfRange)
    }
    Some(first) => {
      // parse_object_body(tokens, start)
      let items: @vec.Vec[(String, JSONValue)] = @vec.Vec::[]
      if (first != "{") {
        return Err(ExpectToken("{"))
      }
      let mut cur = start + 1 // skip "{"
      while cur < tokens.length() {
        let next_opt = tokens.nth(cur)
        if next_opt.is_empty() {
          return Err(ExpectToken("}"))
        }
        let next = next_opt.unwrap()
        
        if next == "," {
          // validate next is not "}"
          // let next_opt = tokens.nth(cur + 1)
          // if next_opt.is_empty() {
          //   return Err(ParseError::OutOfRange)
          // } else {
          //   let next = next_opt.unwrap()
          //   if next == "}" {
          //     return Err(ExpectToken("}"))
          //   }
          // }
          cur += 1
          continue
        }
        if next == "}" {
          break
        }

        let key = next
        let colon_opt = tokens.nth(cur + 1)
        if colon_opt.is_empty() {
          return Err(ParseError::OutOfRange)
        }
        let colon = colon_opt.unwrap()
        if colon != ":" {
          return Err(ExpectToken(":"))
        }
        match parse_literal(tokens, cur + 2) {
          Ok((v, end)) => {
            let mut k = ""
            for i = 1; i < key.length() - 1; i = i + 1 {
              k += key.get(i).to_string()
            }
            items.push((k, v))
            cur = end
          }
          Err(reason) => {
            return Err(reason)
          }
        }
      }

      // check end is "}"
      let end = tokens.nth(cur)
      if end.is_empty() {
        return Err(ParseError::OutOfRange)
      }
      match end.unwrap() {
        "}" => {
          Ok((items.to_list(), cur))
        }
        _ => {
          return Err(ExpectToken("}"))
        }
      }
    }
  }
}

pub fn parse_array(tokens: List[String], start: Int) -> Result[(List[JSONValue], Int), ParseError] {
  // println("parse_array \(start)")
  let items: @vec.Vec[JSONValue] = @vec.Vec::[]

  let first = tokens.nth(start)
  if first.is_empty() {
    return Err(ParseError::OutOfRange)
  }
  if (first.unwrap() != "[") {
    return Err(ParseError::ExpectToken("["))
  }
  let mut cur = start + 1 // skip "["

  while cur < tokens.length() {
    let next_opt = tokens.nth(cur)
    if next_opt.is_empty() {
      return Err(ParseError::OutOfRange)
    }
    let next = next_opt.unwrap()
    if next == "," {
      let next_opt = tokens.nth(cur + 1)
      if next_opt.is_empty() {
        return Err(ParseError::OutOfRange)
      }
      if next_opt.unwrap() == "]"{
        return Err(ParseError::Message("Unexpected , before ]"))
      }
      cur += 1
      continue
    }
    if next == "]" {
      break
    }
    match parse_literal(tokens, cur) {
      Ok((v, end)) => {
        items.push(v)
        cur = end
      }
      Err(reason) => {
        return Err(reason)
      }
    }
  }

  // check end is "]"
  let end = tokens.nth(cur)
  if end.is_empty() {
    return Err(ParseError::OutOfRange)
  }
  match end.unwrap() {
    "]" => {
      Ok((items.to_list(), cur))
    }
    _ => {
      return Err(ExpectToken("]"))
    }
  }
}

pub fn parse(input: String) -> Result[JSONValue, ParseError] {
  let tokens = tokenize(input)
  match parse_literal(tokens, 0) {
    Ok((v, idx)) => {
      if idx < tokens.length() {
        return Err(ParseError::ExpectEOF)
      }
      Ok(v)
    }
    Err(reason) => {
      Err(reason)
    }
  }
}

test "object" {
  @assertion.assert_eq(
    parse(
      #| {
      #|  "hello": "world",
      #|  "foo": "bar"
      #| }
    ).unwrap(), 
    JSONValue::Object(
      List::[
        ("hello", JSONValue::String("world")),
        ("foo", JSONValue::String("bar")),
      ]
    )
  )?
}

// test "int number" {
//   @assertion.assert_eq(
//     parse(
//       #| 1
//     ).unwrap(),
//     JSONValue::IntNumber(1)
//   )?
// }


test "object blank" {
  @assertion.assert_eq(
    parse(
      #| {}
    ).unwrap(), 
    JSONValue::Object(
      List::[
      ]
    )
  )?
}

test "array" {
  @assertion.assert_eq(
    parse(
      #| { "hello": [1, 2] }
    ).unwrap(), 
    JSONValue::Object(
      List::[
        ("hello", JSONValue::Array(List::[
          JSONValue::IntNumber(1),
          JSONValue::IntNumber(2),
        ])),
      ]
    )
  )?
}

test "array blank" {
  @assertion.assert_eq(
    parse(
      #| []
    ).unwrap(), 
    JSONValue::Array(
      List::[]
    )
  )?
}

test "invalid json #1" {
  @assertion.assert_eq(
    parse(
      #| { "x"
    ),
    Err(ParseError::OutOfRange)
  )?
}

test "invalid json #2" {
  @assertion.assert_eq(
    parse(
      #| { "x" "y"
    ),
    Err(ParseError::ExpectToken(":"))
  )?
}

test "invalid json #3" {
  @assertion.assert_eq(
    parse(
      #| []]
    ),
    Err(ParseError::ExpectEOF)
  )?
}

test "invalid json #4" {
  @assertion.assert_eq(
    parse(
      #| [1
    ),
    Err(ParseError::OutOfRange)
  )?
}
test "null" {
  @assertion.assert_eq(
    parse(
      #| { "hello": null }
    ).unwrap(), 
    JSONValue::Object(
      List::[
        ("hello", JSONValue::Null),
      ]
    )
  )?
}


// test "invalid json #5" {
//   @assertion.assert_eq(
//     parse(
//       #| [1,2}
//     ),
//     Err(ParseError::ExpectToken("]"))
//   )?
// }

// test "invalid json #3" {
//   @assertion.assert_eq(
//     parse(
//       #| { "x" : "y", "}"
//     ),
//     Err(ParseError::ExpectToken("}"))
//   )?
// }

