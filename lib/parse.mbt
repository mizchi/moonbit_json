let syntax_tokens : Array[Char] = ['{', '}', '[', ']', '"', ':', ',', ' ', '\n']

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
  ExpectToken(String) // token
  // ExpectTokenButGot(String, String)
  Message(String)
  UnknownExpr(String)
  Unreachable
} derive(Debug, Eq)

pub fn parse(input : String) -> Result[JSONValue, ParseError] {
  let tokens = tokenize(input)
  match parse_literal(tokens, 0) {
    Ok((v, idx)) => {
      // println("~~~ parsed idx \(idx)")
      // debug(tokens.nth(idx))
      if idx != tokens.length() - 1 {
        return Err(ParseError::ExpectEOF)
      }
      Ok(v)
    }
    Err(reason) => Err(reason)
  }
}

fn parse_literal(
  tokens : List[String],
  idx : Int
) -> Result[(JSONValue, Int), ParseError] {
  println("parse_literal \(idx)")
  match tokens.nth(idx) {
    None => {
      let len = tokens.length()
      println("out of range \(idx) in \(len)")
      Err(ParseError::Message("out of range"))
    }
    Some(expr) =>
      match expr {
        "{" =>
          match parse_object(tokens, idx) {
            Ok((members, end)) => return Ok((JSONValue::Object(members), end))
            Err(reason) => return Err(reason)
          }
        "[" =>
          match parse_array(tokens, idx) {
            Ok((items, end)) => return Ok((JSONValue::Array(items), end))
            Err(error) => return Err(error)
          }
        "null" => return Ok((JSONValue::Null, idx))
        _ => {
          // string
          println("expr \(expr)")
          if expr.get(0) == '"' {
            let mut key = ""
            for i = 1; i < expr.length() - 1; i = i + 1 {
              key += expr.get(i).to_string()
            }
            println("trimmed key \(key) return string")
            return Ok((JSONValue::String(key), idx))
          }
          // int or double
          match @strconv.parse_int(expr) {
            Ok(v) => return Ok((JSONValue::IntNumber(v), idx))
            _ => {
              // or double
              let double = @strconv.parse_double(expr)
              if double.is_ok() {
                return Ok((JSONValue::DoubleNumber(double.unwrap()), idx))
              }
            }
          }
          Err(ParseError::UnknownExpr(expr))
        }
      }
  }
}

fn parse_object(
  tokens : List[String],
  start : Int
) -> Result[(List[(String, JSONValue)], Int), ParseError] {
  println("parse_object \(start)")
  match tokens.nth(start) {
    None => return Err(ParseError::OutOfRange)
    Some(first) => {
      // parse_object_body(tokens, start)
      let items : @vec.Vec[(String, JSONValue)] = @vec.Vec::[]
      if first != "{" {
        return Err(ExpectToken("{"))
      }
      let mut cur = start + 1 // sheck "{" <key>
      // always expect <key> : <value>
      while cur < tokens.length() {
        match tokens.nth(cur) {
          None => return Err(ExpectToken("} or , \"<key>\""))
          // maybe blank object
          Some("}") => return Ok((items.to_list(), cur))
          // expect string key
          Some(key) => {
            println("key \(key) \(cur)")
            match tokens.nth(cur + 1) {
              Some(":") => () // ok
              _ => return Err(ExpectToken(":"))
            }
            // consume key : val
            match parse_literal(tokens, cur + 2) {
              Ok((v, end)) => {
                // value parsed
                // println("value \(stringify)")
                let mut k = ""
                for i = 1; i < key.length() - 1; i = i + 1 {
                  k += key.get(i).to_string()
                }
                items.push((k, v))
                // debug
                // let _ = tokens.nth(end + 1)
                {
                  let next_of_end = tokens.nth(end + 1)
                  debug(v)
                  println("next of end \(next_of_end)")
                }
                // peak next token
                match tokens.nth(end + 1) {
                  Some("}") => {
                    println("found } : end \(end)")
                    return Ok((items.to_list(), end + 1))
                  }
                  None => return Err(ExpectToken("} or ,"))
                  Some(",") => {
                    cur = end + 2 // { "x": 1 , <here>
                    println("found , : move to \(cur)")
                    continue
                  }
                  Some(_) => return Err(ExpectToken("} or ,"))
                }
              }
              Err(reason) => return Err(reason)
            }
          }
        }
      }
      Err(ParseError::Unreachable)
      // parse end
      // match tokens.nth(cur) {
      //   Some("}") => Ok((items.to_list(), cur))
      //   Some(_) => Err(ExpectToken("}"))
      //   None => Err(ExpectToken("} or ,"))
      // }
    }
  }
}

fn parse_array(
  tokens : List[String],
  start : Int
) -> Result[(List[JSONValue], Int), ParseError] {
  println("parse_array \(start)")
  let items : @vec.Vec[JSONValue] = @vec.Vec::[]
  let first = tokens.nth(start)
  if first.is_empty() {
    return Err(ParseError::OutOfRange)
  }
  if first.unwrap() != "[" {
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
      if next_opt.unwrap() == "]" {
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
        cur = end + 1
      }
      Err(reason) => return Err(reason)
    }
  }
  // check end is "]"
  let end = tokens.nth(cur)
  if end.is_empty() {
    return Err(ParseError::ExpectEOF)
  }
  match end.unwrap() {
    "]" => Ok((items.to_list(), cur))
    _ => return Err(ExpectToken("]"))
  }
}

test "parse null" {
  @assertion.assert_eq(parse("null"), Ok(JSONValue::Null))?
}

test "parse string" {
  @assertion.assert_eq(parse("\"hi\""), Ok(JSONValue::String("hi")))?
}

test "parse int" {
  @assertion.assert_eq(parse("1"), Ok(JSONValue::IntNumber(1)))?
}

test "parse double" {
  @assertion.assert_eq(parse("1.1"), Ok(JSONValue::DoubleNumber(1.1)))?
}

test "parse blank object" {
  @assertion.assert_eq(parse("{}"), Ok(JSONValue::Object(List::[])))?
}

test "parse 1 item object" {
  @assertion.assert_eq(
    parse("{ \"key\": \"val\" }"),
    Ok(JSONValue::Object(List::[("key", JSONValue::String("val"))])),
  )?
}

test "parse multi items object" {
  @assertion.assert_eq(
    parse("{ \"key\": \"val\", \"x\": \"y\" }"),
    Ok(
      JSONValue::Object(
        List::[("key", JSONValue::String("val")), ("x", JSONValue::String("y"))],
      ),
    ),
  )?
}

test "parse nested object" {
  @assertion.assert_eq(
    parse("{ \"key\": { \"v\": 1 } }"),
    Ok(
      JSONValue::Object(
        List::[
          ("key", JSONValue::Object(List::[("v", JSONValue::IntNumber(1))])),
        ],
      ),
    ),
  )?
}

test "parse blank array" {
  @assertion.assert_eq(
    parse(

      #| []
      ,
    ),
    Ok(JSONValue::Array(List::[])),
  )?
}

test "parse 1 item array" {
  @assertion.assert_eq(
    parse(

      #| [1]
      ,
    ),
    Ok(JSONValue::Array(List::[JSONValue::IntNumber(1)])),
  )?
}

test "parse 2 items array" {
  @assertion.assert_eq(
    parse(

      #| [1, 2]
      ,
    ).unwrap(),
    JSONValue::Array(List::[JSONValue::IntNumber(1), JSONValue::IntNumber(2)]),
  )?
}

test "parse error : expect eof" {
  @assertion.assert_eq(
    parse(

      #| {}}
      ,
    ),
    Err(ParseError::ExpectEOF),
  )?
}

test "parse error : expect eof" {
  @assertion.assert_eq(
    parse(

      #| 1,
      ,
    ),
    Err(ParseError::ExpectEOF),
  )?
}

test "parse error : invalid object" {
  @assertion.assert_eq(
    parse(

      #| {
      ,
    ),
    Err(ParseError::Unreachable),
  )?
}

test "parse error : expect object end" {
  @assertion.assert_eq(
    parse(

      #| { "v": 1
      ,
    ),
    Err(ParseError::ExpectToken("} or ,")),
  )?
}

test "parse error : out of range" {
  @assertion.assert_eq(
    parse(

      #| { "x"
      ,
    ),
    Err(ParseError::ExpectToken(":")),
  )?
}

test "invalid json #2" {
  @assertion.assert_eq(
    parse(

      #| { "x" "y"
      ,
    ),
    Err(ParseError::ExpectToken(":")),
  )?
}

test "invalid json #3" {
  @assertion.assert_eq(
    parse(

      #| []]
      ,
    ),
    Err(ParseError::ExpectEOF),
  )?
}

// test "invalid json #4" {
//   @assertion.assert_eq(
//     parse(

//       #| [1
//       ,
//     ),
//     Err(ParseError::OutOfRange),
//   )?
// }

// FIXME
test "invalid json #5" {
  @assertion.assert_eq(
    parse(

      #| [1,2}
      ,
    ),
    Err(ParseError::UnknownExpr("}")),
  )?
}

// FIXME
test "invalid json #3" {
  @assertion.assert_eq(
    parse(

      #| { "x" : "y", "}"
      ,
    ),
    Err(ParseError::ExpectToken("}")),
  )?
}
