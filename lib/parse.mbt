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
} derive(Debug, Eq)

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

fn parse_literal(tokens: List[String], idx: Int) -> Result[(JSONValue, Int), ParseError] {
  // if (tokens.length() <= idx) {
  //   return Err(ParseError::OutOfRange)
  // }
  match tokens.nth(idx) {
    None => {
      // Err(ParseError::OutOfRange)
      let len = tokens.length()
      println("out of range \(idx) in \(len)")
      Err(ParseError::Message("out of range"))
    }
    Some(expr) => {
      let first = expr.get(0)
      let last = expr.get(expr.length() - 1)
      if expr == "{" {
        match parse_object(tokens, idx) {
          Ok((members, end)) => {
            return Ok((JSONValue::Object(members), end + 1))
          }
          Err(reason) => {
            return Err(reason)
          }
        }
      }
      if expr == "[" {
        match parse_array(tokens, idx) {
          Ok((items, end)) => {
            return Ok((JSONValue::Array(items), end + 1))
          }
          Err(error) => {
            return Err(error)
          }
        }
      }
      if expr == "null" {
        return Ok((JSONValue::Null, idx + 1))
      }
      // println("parse_literal \(start)")
      if first == '"' && last == '"' {
        let mut s = ""
        for i = 1; i < expr.length() - 1; i = i + 1 {
          s += expr.get(i).to_string()
        }
        // let value = expr.to_bytes().sub_string(1, expr.length() - 2)
        return Ok((JSONValue::String(s), idx + 1))
      }
      let int = @strconv.parse_int(expr)
      if (int.is_ok()) {
        // println("int found")
        return Ok((JSONValue::IntNumber(int.unwrap()), idx + 1))
      }

      let double = @strconv.parse_double(expr)
      if double.is_ok() {
        return Ok((JSONValue::DoubleNumber(double.unwrap()), idx + 1))
      }
      Err(ParseError::ExpectToken(expr))
    }
  }
  // let expr = tokens.nth(start)
}

fn parse_object(tokens: List[String], start: Int) -> Result[(List[(String, JSONValue)], Int), ParseError] {
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

fn parse_array(tokens: List[String], start: Int) -> Result[(List[JSONValue], Int), ParseError] {
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

test "parse int" {
  @assertion.assert_eq(
    parse("1").unwrap(),
    JSONValue::IntNumber(1)
  )?
}

test "parse double" {
  @assertion.assert_eq(
    parse("1.1").unwrap(),
    JSONValue::DoubleNumber(1.1)
  )?
}

test "parse blank object" {
  @assertion.assert_eq(
    parse("{}").unwrap(),
    JSONValue::Object(List::[])
  )?
}

test "parse 1 item object" {
  @assertion.assert_eq(
    parse("{ \"key\": \"val\" }").unwrap(),
    JSONValue::Object(List::[
      ("key", JSONValue::String("val"))
    ])
  )?
}

test "parse multi items object" {
  @assertion.assert_eq(
    parse("{ \"key\": \"val\", \"x\": \"y\" }").unwrap(),
    JSONValue::Object(List::[
      ("key", JSONValue::String("val")),
      ("x", JSONValue::String("y"))
    ])
  )?
}


test "parse blank array" {
  @assertion.assert_eq(
    parse(
      #| []
    ).unwrap(), 
    JSONValue::Array(List::[]),
  )?
}

test "parse 1 item array" {
  @assertion.assert_eq(
    parse(
      #| [1]
    ).unwrap(), 
    JSONValue::Array(List::[
      JSONValue::IntNumber(1),
    ]),
  )?
}

test "parse 2 items array" {
  @assertion.assert_eq(
    parse(
      #| [1, 2]
    ).unwrap(), 
    JSONValue::Array(List::[
      JSONValue::IntNumber(1),
      JSONValue::IntNumber(2),
    ]),
  )?
}

test "parse error : expect eof" {
  @assertion.assert_eq(
    parse(
      #| {}}
    ),
    Err(ParseError::ExpectEOF)
  )?
}

// test "parse error : out of range" {
//   @assertion.assert_eq(
//     parse(
//       #| { "x"
//     ),
//     Err(ParseError::OutOfRange)
//   )?
// }

// test "invalid json #2" {
//   @assertion.assert_eq(
//     parse(
//       #| { "x" "y"
//     ),
//     Err(ParseError::ExpectToken(":"))
//   )?
// }

// test "invalid json #3" {
//   @assertion.assert_eq(
//     parse(
//       #| []]
//     ),
//     Err(ParseError::ExpectEOF)
//   )?
// }

// test "invalid json #4" {
//   @assertion.assert_eq(
//     parse(
//       #| [1
//     ),
//     Err(ParseError::OutOfRange)
//   )?
// }
// test "null" {
//   @assertion.assert_eq(
//     parse(
//       #| { "hello": null }
//     ).unwrap(), 
//     JSONValue::Object(
//       List::[
//         ("hello", JSONValue::Null),
//       ]
//     )
//   )?
// }

// test "invalid json #5" {
//   @assertion.assert_eq(
//     parse(
//       #| [1,2}
//     ),
//     Err(ParseError::ExpectToken("]"))
//   )?
// }


// test "parse_literal #2" {
//   @assertion.assert_eq(
//     parse_literal(tokenize("null"), 0),
//     Ok((JSONValue::Null, 1))
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

