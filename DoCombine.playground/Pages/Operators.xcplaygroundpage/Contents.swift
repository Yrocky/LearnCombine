//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

public func example(of description: String, action: () -> Void) {
    
    print("\n--- Example of:", description, "---")
    action()
}
print("hello")
example(of: "Transforming operators") {
    /*:
     在Combine中，操作符是除了Publisher和Subscriber之外，最重要的部分
     对**来自Publisher的值**进行**操作**的方法称为`操作符`，
     并且每一个操作符的结果都是返回一个新的Publisher，
     操作符接收upstream，并对数据进行加工处理，然后将结果作为downstream交给下一个操作符
     在加工处理的过程中有可能会产生错误，所以，交给下一个操作符的还可能是error
     */
}

example(of: "collect()") {
    //: collect操作符可以将从Publisher发出的单个值转化成数组
    
    let array = ["a","b","c","d","e"]
    //: 前面我们知道了Combine为Array提供了便利创建Publisher的方法，
    array.publisher
        .sink { (value) in
            print("receive \(value)")
        }.store(in: &subscriptions)
    
    /*:
     但是这样只能让元素一个一个的输出，如果想让元素以一定个数成组输出就可以使用collect，
     在成组中可以直接设置count，还可以使用一个enum来指定成组策略，
     需要注意的是，通过collect操作符处理之后得到的数据类型将是一个Array
     */
    array.publisher
        .collect(2)
        .sink { (value) in
            print("collect receive \(value)")
        }.store(in: &subscriptions)
}

example(of: "map()") {
    //: map操作符和swift基础库中的含义一样，就是将元素进行一个转换处理
    
    let numbers = [1,2,3,4]
    numbers.publisher
        .map { $0 + 1 }
        .sink { print("new number \($0)")}
        .store(in: &subscriptions)
    
    /*:
     map操作符还支持使用keyPath来进行映射
     对keyPath的映射最多支持3个
     */
    struct Roll {
        let die1: Int
        let die2: Int
        let die3: Int
    }
    
    //: 一个keyPath
    Just(Roll(die1: 1, die2: 2, die3: 3))
        .map(\.die1)// 对keyPath的映射等效于 .map { $0.die1 }
        .sink { print("roll.die1: \($0)") }
        .store(in: &subscriptions)
    
    Just(Roll(die1: 10, die2: 20, die3: 30))
        .map(\.die2, \.die3)// 多余1个的keyPath就没有等效的了
        .sink { print("roll.die2: \($0) roll.die3: \($1)") }
        .store(in: &subscriptions)
}


struct ParseError: Error {}
//: 这个func可能会throws一个错误，在使用的时候需要使用try
func romanNumeral(from:Int) throws -> String {
    let romanNumeralDict: [Int : String] =
        [1:"I", 2:"II", 3:"III", 4:"IV", 5:"V"]
    guard let numeral = romanNumeralDict[from] else {
        throw ParseError()
    }
    return numeral
}

//: 在调用romanNumeral方法的时候，需要使用try
let romanNumeralString_3 = try romanNumeral(from: 3)
//print(romanNumeralString_3)

//: 由于内部没有对6的罗马数字映射，这里会抛出一个错误
//let romanNumeralString_6 = try romanNumeral(from: 6)
//print(romanNumeralString_6)


example(of: "tryMap()") {
    
    /*:
     
     在映射数据的时候，总不可能一直返回有效数据，还有可能产生错误，
     或者是map中的逻辑需要try-catch，比如打开文件、除法等等
     这个时候可以使用tryMap，
     */
    Just(9)
        .tryMap { try romanNumeral(from: $0) }
        .sink(receiveCompletion: { print("comp \($0)")},
              receiveValue: { print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "flatMap") {

}

//: [Next](@next)
