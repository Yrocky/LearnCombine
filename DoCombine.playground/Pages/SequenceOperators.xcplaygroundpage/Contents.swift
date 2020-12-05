//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
var str = "Hello, playground"

example(of: "Sequence") {
    /*:
     在前面展示了对Sequence添加的拓展，
     可以很方便的将一个数组、集合等转化为Publisher，
     并将里面的内容进行分发。
     
     不过不同于swift提供的Sequence，Combine框架中对Sequence有专门的操作符,
     并且数据在分发的过程中就相当于是一个Sequence（或者叫做Pipline），
     因此可以获取到一个Publisher分发的所有数据中具有某些意义的数据，比如最大、最小等等。
     */
}

example(of: "min()") {
    
    /*:
     `min()`操作符用来获取当前Publisher分发的所有数据中最小的那个，
     这里就需要等到Publisher分发completion之后才可以获取到，
     这点很好理解，不然Combine并不会知道有多少数据要用于计算。
     */
    
    [1,5,73,10,-8]
        .publisher
        .print()
        .min()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("min value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     除了对Int类型的Publisher操作，还可以对String类型进行操作，
     只要Publisher的Output实现了Equalable协议即可，
     因此如果要对自定义的类型的Publisher进行min操作，自定义类需要遵守并且实现Equalable协议。
     */
    ["a","aa","b","z","-1"]
        .publisher
        .print()
        .min()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("min string value \($0)")})
        .store(in: &subscriptions)
    
    let aPublisher = PassthroughSubject<Int, Never>()
    
    aPublisher
        .print()
        .min()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("min value \($0)")})
        .store(in: &subscriptions)
    
    aPublisher.send(10)
    aPublisher.send(9)
    aPublisher.send(45)
    
    //: 到目前为止，并不会找到最小的值
    
    aPublisher.send(completion: .finished)

    //: aPublisher发送了finished，所有数据分发完毕，这时就可以找到最小数据。
}

example(of: "min() 2") {
    /*:
     当然，总会有特殊的比较需求，比如使用min找到字符串长度最短的元素
     */
    
    ["aa","aaa","a","aaaaa","aaaa"]
        .publisher
        //: 可以在block回调中自行决定min策略
        .min { $0.count < $1.count }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("min shortest value [\($0)]")})
        .store(in: &subscriptions)
}

example(of: "max()") {
    /*:
     有`min()`就会有`max()`，
     `max()`操作符是用于获取publisher分发的数据中最大的，
     同样的，也是需要publisher发送了completion之后，
     才可以执行运算获取目标数据。
     */
    (1...8)
        .publisher
        .max()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("max value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     其也有一个变种操作符：`max(by:)`，
     用于提供自定义的block逻辑，让Combine运算获取目标数据。
     */
    
    [2,4,6,5]
        .publisher
        //: 这里仅仅是做一个实例，用于了反向操作（求最小）
        .max { $0 > $1 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("max value \($0)")})
        .store(in: &subscriptions)
}

example(of: "first & last") {
    
    /*:
     `first()`和`last()`这两个操作符前面已经解释过了，这里再稍微复习一下。
     
     `first()`操作符不需要publisher发送completion，而`last()`需要。
     */
    
    let aPublisher = PassthroughSubject<Int, Never>()
    
    aPublisher
        .print("aPublisher")
        .first()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("first value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     对Publisher使用了`first()`操作符之后，其会在分发一次数据之后，
     会为下游订阅者分发一个cancel，之后再分发的数据也不会交给下游订阅者。
     */
    aPublisher.send(1)
    aPublisher.send(2)
    
    /*:
     作为`first()`的变种，`first(where:)`支持自定义逻辑来决定要获取的首个数据，
     同样的，在下游订阅者收到目标数据之后，publisher会给其发送一个cancel，
     并且publisher之后分发的数据并不会传递给下游订阅者。
     */
    let bPublsier = PassthroughSubject<Int, Never>()
    
    bPublsier
        .print("bPublsier")
        .first { $0 == 3 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("first value \($0)")})
        .store(in: &subscriptions)
    
    bPublsier.send(1)
    bPublsier.send(2)
    bPublsier.send(3)
    bPublsier.send(4)
    
    /*:
     `last()`和`first()`相反，其用于获取分发数据中最后的一个，
     所以需要publisher发送completion才可以得到目标数据。
     */
    let cPublisher = PassthroughSubject<Int, Never>()
    
    cPublisher
        .print("cPublisher")
        .last()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("last value \($0)")})
        .store(in: &subscriptions)
    
    cPublisher.send(1)
    cPublisher.send(3)
    cPublisher.send(5)
    
    cPublisher.send(completion: .finished)
    
    /*:
     同样的，`last()`也有一个变种：`last(where:)`，
     通过where回调自定义逻辑获取目标数据。
     */
    let dPublisher = PassthroughSubject<Int, Never>()
    
    dPublisher
        .print("dPublisher")
        .last(where: { $0 == 3 })
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("last value \($0)")})
        .store(in: &subscriptions)
    
    dPublisher.send(1)
    dPublisher.send(3)
    dPublisher.send(5)
    dPublisher.send(3)
    
    dPublisher.send(completion: .finished)
}

example(of: "output(at:)") {
    /*:
     `output(at:)`操作符用于获取publisher分发的数据中第几个索引处的数据。
     */
    
    (1...7)
        .publisher
        .print()
        .output(at: 2)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     如果目标索引超过了publisher分发数据的长度，
     那就不会分发任何数据给下游订阅者。
     */
    (1...7)
        .publisher
        .print()
        .output(at: 9)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "output(in:)") {
    /*:
     和`output(at:)`相对的是`output(in:)`操作符，
     这里的`in`和**Output**、**Input**中的`in`不一样，
     这里的`in`的意思：处于、在某个范围内。
     这个结合`output(in:)`接收的参数就可以很好的理解了，
     其接收一个`RangeExpression`类型的数据，也就是范围。
     
     同样的，`output(at:)`中的`at`指的是：处于、位于、在某某索引处。
     */
    
    (1...7)
        .publisher
        .print()
        .output(in: (1...3))
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "") {
    /*:
     在Sequence中除了对特殊位置（first()、last()、output(in:)、output(at:)）、
     特殊含义（min()、max()）的目标数据的获取，
     还有针对整个Sequence来说有意义的指标，
     比如publisher分发的数据总数、分发的数据中是有包含有某些特殊数据等等。
     */
}

example(of: "count()") {
    /*:
     `count()`操作符不对publisher分发的数据做处理，
     它会将publisher分发数据的总数作为一个特殊的数据，交给下游订阅者。
     */
    
    (1...9)
        .publisher
        .count()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("count \($0)")})
        .store(in: &subscriptions)
}

example(of: "contains(_:)") {
    /*:
     `contains(_:)`操作符用于获取publisher所分发的数据中是否包含特殊数据，
     并将结果（布尔值类型）交给下游订阅者。
     */
    ["He","hello","hero","her"]
        .publisher
        //: 如果参数是`he`，很明显是不包含的，下游订阅者会收到一个false数据
        .contains("he")
        //: 如果参数是`He`，下游订阅者会收到一个true数据
//        .contains("He")
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("contains？ \($0)")})
        .store(in: &subscriptions)
    
    /*:
     其还有一个变种操作符：`contains(where:)`，
     接收一个block回调，用于自定义逻辑来判断是否存在目标数据
     */
    ["He","hello","hero","her"]
        .publisher
        .contains(where: { $0.contains("he")})
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("contains？ \($0)")})
        .store(in: &subscriptions)
    
    /*:
     在使用自定义类型作进行分发的时候，其contains操作符的使用实例。
     */
    
    struct Person{
        let age: Int
        let name: String
    }
    
    let people = [
        (19,"rocky"),
        (29,"rocky"),
        (39,"rocky"),
        ].map(Person.init)
        .publisher
    
    people
        .contains { $0.age == 29 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("contains? \($0)")})
        .store(in: &subscriptions)
}

example(of: "allSatisfy(_:)") {
    /*:
     `allSatisfy(_:)`操作符用于校验从publisher分发的所有数据是否能通过参数中的逻辑，
     同样的，经过该操作符处理之后，下游订阅者收到的是布尔值数据类型。
     */
    ["He","hello","hero","her"]
        .publisher
        .allSatisfy { $0.contains("e") }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("allSatisfy? \($0)")})
        .store(in: &subscriptions)
}
example(of: "reduce(_:,_:)") {
    
    /*:
     `reduce(_:,_:)`用于对publisher分发的数据进行增量处理，
     这一点上和`scan(_:,_:)`类似，同样的可以设定初始值，设定处理增量的逻辑。
     */
    
    [1,3,5,7,9]
        .publisher
        .reduce(0) { $0 + $1 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("reduce \($0)")})
        .store(in: &subscriptions)
    
    /*:
     并不要被这种相同的地方所迷惑，下面看下他们不同的地方。
     
     从定义上看下两者的区别：
     
     ```
     public func reduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Publishers.Sequence<Elements, Failure>.Output) -> T) -> Result<T, Failure>.Publisher

     public func scan<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Publishers.Sequence<Elements, Failure>.Output) -> T) -> Publishers.Sequence<[T], Failure>
     ```
     
     `reduce`的block回调返回的是一个`Result`，表示期望得到一个值或者或者一个错误；
     而`scan`的block回调返回的是一个`Publishers.Sequence`。
     也就是说，reduce处理之后，返回的是**一个数据**，下游订阅者只能收到这一个数据；
     而经过scan处理之后的数据，会以增量的方式，**每增加一个，就对下游订阅者分发一次数据**。
     
     通过控制台的输出也可以验证这一点：
     
     ```
     reduce 25
     
     scan 1
     scan 4
     scan 9
     scan 16
     scan 25
     ```
     */
    [1,3,5,7,9]
        .publisher
        .scan(0) { $0 + $1 }
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("scan \($0)")})
        .store(in: &subscriptions)
    
    /*:
     `reduce(_:,_:)`操作符中第二个参数还可以使用运算符，
     比如下面使用`+`来替换上面对增量自增的操作。
     */
    [1,3,5,7,9]
        .publisher
        .reduce(0, +)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("reduce \($0)")})
        .store(in: &subscriptions)
}

//: [Next](@next)
