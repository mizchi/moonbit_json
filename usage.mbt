/// `.mbt` は rust によく似た moonbit 言語です。
/// moonbit は、以下の特徴を持ちます
/// 
/// - GC はありません。ライフタイムを書く必要がありません。
/// - ジェネリクスは `T<X>` ではなく `T[X]` と記述します
/// - テストは `test { ... }` で記述します。
/// - *_test.mbt はテストファイルとして扱われます
/// - コアライブラリ
///   - Array: Immutable Array
///   - List[T]: Immutable List
///   - @vec.Vec[T]: Mutable List
///   - @map.Map[K, V]: Immutable Map
///   - @hashmap.HashMap[K, V]: Mutable Map
///   - Result[T, E]: だいたい Rust の Result と同じ
///   - Option[T]: だいたい Rust の Option と同じ
///   - @assertion.assert_eq(a, b): テスト用のアサーション
/// - モジュールシステム
///   - 同じディレクトリに存在する `*.mbt` の pub fn を呼び出すことができます
///   - 他のモジュールを使うには moon.pkg.json の import に記述します
///     - 例: { "import": ["mizchi/json/lib"] }
///     - 例: { "import": [{ "path": "mizchi/other/lib", "alias": "other" }] }
///   - 外部モジュールを使うには、moon.pkg.json の deps に記述します

// function
fn add(a : Int, b : Int) -> Int {
  return a + b
}

// generics
fn _self[T](v : T) -> T {
  return v
}

// generics trait
fn _lge[X : Compare](a : X, b : X) -> Bool {
  return a >= b
}

// result unwrap
fn _try_xxx() -> Result[Int, Int] {
  let v : Result[Int, Int] = Ok(1)
  let x = v?
  Ok(x)
}

// data structure
enum T {
  A
  B
}

// complex enum
enum T2[X] {
  A(Int)
  B(X)
} derive(Debug)

struct Point {
  x : Int
  y : Int
} derive(Debug)

fn Point::new(x : Int, y : Int) -> Point {
  return Point::{ x, y }
}

fn distance(self : Point, other : Point) -> Double {
  sqrt((self.x * other.x + self.y * other.y).to_double())
}

// Generics and derived trait
struct Point3d[N] {
  x : N
  y : N
  z : N
} derive(Debug)

// newtype
// type Point3dInt Point3d[Int]

// trait
trait Animal {
  speak(Self) -> Unit
}

struct Duck {
  name : String
}

fn speak(self : Duck) -> Unit {
  let name = self.name
  println("\(name): Quak!")
}

fn _usage_example() -> Unit {
  println("Hello, World!")

  // variable
  let _x = "hello"
  let mut y : Int = 2
  let _multiline_text =
    #| hello
    #| world
    #| multiline

  y = 3
  let p = Point::{ x: 1, y: 2 }
  println(p.distance(Point::{ x: 3, y: 4 }))
  debug(p)

  // function and call
  let _ = add(1, 2)
  // pipeline
  let _ = 1 |> add(2) |> add(4)

  // call ./foo.mbt: pub fn foo() -> Int { 1 }
  // let _ = foo()

  // array and iterator
  let list = [1, p.x, p.y]
  let mapped = list.map(fn(x) -> Int { return x + 1 })
  println(mapped)

  // inference
  let _ : Int = _self(1) // as Int

  // trait
  let duck = Duck::{ name: "Donald" } as Animal
  duck.speak()

  // if else
  if y == 2 {
    println("y is 1")
  } else {
    println("y is not 1")
  }

  // match
  let mut m = T::A
  m = T::B
  let _ = match m {
    T::A => 1
    T::B => 2
  }

  // for
  for i = 1; i < 5; i = i + 1 {
    print(i)
  }
  println("")

  // while
  let mut i = 0
  while i > 0 {
    i = i - 1
  }

  // loop
  let xs = List::[1, 2, 3]
  loop xs {
    Nil => break
    Cons(x, Nil) => {
      println(x)
      continue Nil
    }
    Cons(x, xs) => {
      println(x)
      continue xs
    }
  }
}

// inline test
test {
  let a = 1
  let b = 2
  let c = add(a, b)
  @assertion.assert_eq(c, 3)?
}
