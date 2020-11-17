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
     在Combine中，操作符是除了`Publisher`和`Subscriber`之外，最重要的部分。
     对**来自Publisher的值**进行**操作**的方法称为`操作符`，
     并且每一个操作符的结果都是返回一个`新的Publisher`，
     操作符接收`upstream`，并对数据进行加工处理，
     然后将结果作为`downstream`交给下一个操作符，
     在加工处理的过程中有可能会产生错误，
     所以，交给下一个操作符的还可能是error，
     这个时候就需要使用`try-like`变种的操作符来处理对应的数据。
     */
}

example(of: "collect()") {
    //: collect操作符可以将从Publisher发出的单个值转化成数组
    
    let array = ["a","b","c","d","e"]
    //: 前面我们知道了Combine为Array提供了便利创建Publisher的方法，
    array
        .publisher
        .sink { print("receive \($0)") }
        .store(in: &subscriptions)
    
    /*:
     普通的但是这样只能让元素一个一个的输出，
     如果想让元素以`一定个数成组`输出就可以使用collect。
     在成组中可以直接设置`count`，让数据以一定的个数成组输出；
     还可以使用一个`TimeGroupingStrategy`的enum来指定成组策略，
     策略可以使按照`time`的，还可以是按照`timeOrCount`的。
     需要注意的是，通过collect操作符处理之后得到的数据类型将是一个Array
     */
    array
        .publisher
        .collect(2)
        // 通过collect处理之后，传递的将不再是String，而是Array
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
     map操作符还支持使用`keyPath`来进行映射，
     对keyPath的映射最多支持**3个**。
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
     或者是map中的逻辑需要try-catch，比如打开文件、除法等等，
     这个时候可以使用`tryMap`。
     */
    Just(9)
        .tryMap { try romanNumeral(from: $0) }
        .sink(receiveCompletion: { print("comp \($0)")},
              receiveValue: { print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "flatMap") {
    /*:
     `flatMap`可以将多个publisher合并成一个publisher，
     经过了flatMap处理之后的publisher和之前的多个publisher有可能并不是同一种类型
     
     使用flatMap可能会引起内存问题，
     因为它会缓存它的所有发布者，以更新它在下游发出的单个发布者。
     */
//    Just("s")
//    .flatMap(<#T##transform: (String) -> Publisher##(String) -> Publisher#>)
//        .flatMap(maxPublishers: .max(2), <#T##transform: (String) -> Publisher##(String) -> Publisher#>)
        
}

example(of: "replaceNil(with:)") {
    
    /*:
     在前面的`map`中可以将对应的数据进行转化，有可能会转化失败（trymap），
     也有可能本来的数据中就有空（nil、null等）数据，这个时候可以使用`replaceNil`。
     
     下面的例子中，如果不加`.eraseToAnyPublisher`，那么sink中输出的是`Optional<String>`，
     如果使用了`.eraseToAnyPublisher`，则会获得对应解包之后的数据：`String`。
     
     ??和replaceNil有一个细微但是很重要的区别，
     通过? ?解包的数据仍然可以产生nil结果，但replaceNil并不会，
     将replaceNil的用法更改为以下，您将得到一个错误，该可选选项必须被取消包装:
     */
    
    ["a",nil,"b","c","d",nil]
        .publisher
        .eraseToAnyPublisher()// https://bit.ly/30M5Qv7
        .replaceNil(with: "-")
//        .replaceNil(with: "-" as String?)// 使用这行代码会报错
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "replaceEmpty(with:)") {
    
    /*:
     如果一个publisher发送的消息中没有值，或者说是一个空值，
     可以使用`replaceEmpty(with:)`来将其进行替换，或者说插入一个约定好的值。
     
     最好解释的一个就是，通过map操作得到一个`Empty`类型的Publisher，
     因为它本身是没有值的，所以可以约定将其改为约定值。
     */
    
    let empty = Empty<Int, Never>(completeImmediately: true)
    // Empty的立即completion还不知道是什么意思了
    empty
        // 这样，会立马收到一个completion的消息，但不会得到value
        .sink(receiveCompletion: { print("completion \($0)")},
              receiveValue: { print("value \($0)")})
        .store(in: &subscriptions)
    
    empty
        // 通过replaceEmpty处理之后，就可以变相的`插入`一个具体的值
        .replaceEmpty(with: 100)
        .sink(receiveCompletion: {print("replace completion \($0)")},
              receiveValue: {print("replace value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     除了`replaceNil`、`replaceEmpty`之外，还有`replaceError`这个操作符，
     待学。
     */
}

example(of: "scan(_:_:)") {
    /*:
     对增量的处理，简单解释就是，求1到100之间的数字的和，
     每两个数相加之后都会作为一个值和之后的第三个数相加。
     在Combine中是使用`scan(_:_:)`来完成这个操作的。
     */
    
    [1,2,3,4,5,6,7,8,9]
        .publisher
        .eraseToAnyPublisher()
        /*:
         scan有两个参数，
         第一个是初始值，
         第二个是一个block回调，用于对每个增量以及前面的值做处理。
         $0就是之前的所有增量的和，$1是当前遍历到的值
         */
        .scan(0) { $0 + $1 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     scan操作符也是可能返回错误的，还有一个变形：`tryScan`
     */
//    Just([1,2,3])
//    .eraseToAnyPublisher()
//        .tryScan(0) { $0 + $1 }
}


//: [Next](@next)
