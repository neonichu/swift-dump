# Swift Dump

PoC of a class-dumpy tool for Swift classes.

## Usage

```
$ file test
test: Mach-O 64-bit executable x86_64
$ ./swift-dump.rb test
// Code generated from `test`
import Foundation

class Foo {
let i: Int = 0 
var j: Int = 0 
var k: Int { return 0 } 
func add(Int, b : Int) -> String { return "" }
func bar() -> Int { return 0 }
func nothing() -> () {}
}
```

## Status

This is __very__ limited right now, with no support for structs, generics or initializers.

## Author

Boris Bügling, boris@icculus.org

## Help needed

Follow [@NeoNacho](https://twitter.com/NeoNacho) to help me beat [@orta](https://twitter.com/orta) in followers count.

## License

swift-dump is available under the MIT license. See the LICENSE file for more info.
