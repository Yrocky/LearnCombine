//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
var str = "Hello, playground"

example(of: "filter") {

    /*:
     过滤操作更容易产生一个error，所以很多filter操作都会有try-类型的操作符
     */
    
    (1...10)
        .publisher
        // block中满足条件的元素会被publisher发送出去
        .filter { $0%3 == 0 }
        .sink(receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "removeDuplicates") {
    /*:
     `removeDuplicates`操作符会将publisher中重复的数据进行移除
     这里的重复是指和前一个数据重复，
     比如[1,1,2,1]第二个1就是重复的，但是第三个1并不是重复的，
     经过`removeDuplicates`处理之后的结果是：[1,2,1]，
     这样的操作符可以避免下游对相同的数据进行重复计算。
     */
    [1,1,2,3,1,4,5,5,1,6,1]
        .publisher
        .eraseToAnyPublisher()
        .removeDuplicates()
        .sink(receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "compactMap") {
    /*:
     `compactMap()`操作符会将非nil的数据重新发布出去，而nil的数据将会被丢弃
     */
    
    ["a","2","0.23","we","1/5","6/3","6%2"]
        .publisher
        .compactMap {Float($0)}
        .sink(receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "ignoreOutput()") {
    
    /*:
     `ignoreOutput()`操作符会忽视所有的输入，并且不进行任何的输出
     */
    ["a","2","0.23"]
        .publisher
        .ignoreOutput()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "first(where:)") {
    /*:
     `first(where:)`操作符会获取所有的输入中的第一个目标元素，
     在这之前和之后的所有数据都会被忽略，之前的会被忽略，之后的会被抛弃
     
     通过`cancel`来不正常的结束数据接收
     */
    
    (1...100)
        .publisher
        .print()
        .first(where: {$0%3 == 0})// 取余操作，找第一个3的倍数的数据
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    print("one by one")

    let publisher = PassthroughSubject<Int, Never>()
    publisher
        .print()
        .first(where: {$0%3 == 0})
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    publisher.send(1)
    publisher.send(3)
    publisher.send(4)
    publisher.send(6)
    publisher.send(9)
    
    /*:
     由于first(where:)是前项获取的，并不需要所有的数据，
     所以，只要数据满足了条件，就会被发布出去，并且也不会接收之后的数据，
     这一点和下面的`last(where:)`并不一样
     */
}

example(of: "last(where:)") {
    /*:
     `last(where:)`操作符会将所有的数据中最后一个满足条件的值进行发布
     Combine会将所有的数据进行缓存，从中得出最后一个满足条件的值
     这一点和`first(where:)`不同，first(where:)只要得到满足条件的值，就不接收输入了
     */
    (1...10)
        .publisher
        .print()
        .last(where: {$0 % 6 == 0})
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*
     上面演示的是一次性将所有的数据都发布完成，那么如果是依次发布呢？
     */
    
    let publisher = PassthroughSubject<Int, Never>()
    print("one by one")
    publisher
        .print()
        .last(where: { $0 % 2 == 0 })
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    publisher.send(1)
    publisher.send(2)
    publisher.send(3)
    publisher.send(4)
    publisher.send(5)
    
    /*:
     执行上面的代码，发现并不会得到对应的值（4），这是因为没有收到`finish`消息，
     后面还有可能存在最后一个符合条件的值，
     如果publisher发送了一个.finished之后，就会得到对应的值。
     可以看出来，`last(where:)`这个操作符需要publisher执行了`.finished`才有效，极度依赖后者。
     */
    publisher.send(completion: .finished)
}

example(of: "drop(while:)") {
    /*:
     `drop(while:)`操作符会不发布任何元素，直到block中返回false为止
     也就是说，当得到了第一个不满足该条件的元素，才开始发布之后的元素，
     类似于`do-while`，这里的do是一个drop操作，
     在while的判断为true之前所有的元素都要drop掉
     
     这个操作符和.max()有关系，比如，前面两个元素：1、2，使用print()打印出来如下
     
     ```
     receive value: (1)
     request max: (1) (synchronous)
     receive value: (2)
     request max: (1) (synchronous)
     ```
     
     但是在4之后的元素，打印却是：
     ```
     receive value: (4)
     receive value: (5)
     ...
     ```
     
     也就是说，在满足drop条件的时候，同步(synchronous)请求了一次`.max(1)`，
     而在第一次不满足之后，就不会发送请求了
     
     */
    [1,2,3,2,3,4,5,2,3,4,8,9,4]
        .publisher
//        .print()
        .drop(while: { $0 != 4 })
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "dropFirst(_:)") {
    
    /*:
     `dropFirst(_:)`会丢弃指定个数之前的数据，比如指定为3，就丢弃前三个
     */
    
    [1,2,3,4,5,3,4,5,6,7,8,5,8]
        .publisher
        .dropFirst(3)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom:)") {
    /*:
     `drop(untilOutputFrom:)`操作符会涉及到两个publisher，
     一个publisher绑定另一个publisher，
     直到收到另一个publisher发布的元素之前，将所有的元素都忽略掉
     
     */
    let isReadly = PassthroughSubject<Int, Never>()
    let publisher = PassthroughSubject<Int, Never>()
    
    publisher
        // publisher和idReady两个进行绑定，
        // 直到isReady开始发布元素，publisher发布的元素都不会被处理
        .drop(untilOutputFrom: isReadly)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    (1...10).forEach { value in
        publisher.send(value)
        if value == 4 {
            // isReady开始发布元素，publisher的subscriber才开始收到来自pubisher的元素
            isReadly.send(100)
        }
    }
}

example(of: "prefix(_:)") {
    /*:
     `prefix(_:)`只会发布前几个数据，之后的数据并不会发出，
     和上面的`drop(first:)`和`drop(while:)`不同的是，这个操作符直接指明drop前几个元素
     另外一点是，它是通过`cancel`来结束
     */
    (1...10)
        .publisher
        .print()
        .prefix(3)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "prefix(while:)") {
    /*:
     `prefix(while:)`是另一种用于限制发布元素的指令，
     类似于`do-while`，publisher会依次发布元素，直到while的判断语句为True，跳出循环为止。
     */
    (1...10)
        .publisher
        .prefix(while: { $0 != 4})
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "prefix(untilOutputFrom:)") {
    /*:
     使用`prefix(untilOutputFrom:)`，可以让当前publisher依赖另一个publisher，
     和`drop(untilOutputFrom:)`不同的是，当前publisher会一直产生数据，并进行发布，
     直到依赖的publisher开始产生数据传递才停止
     */
    
    let isReady = PassthroughSubject<Int, Never>()
    let publisher = PassthroughSubject<Int, Never>()
    
    publisher
        .print()
        .prefix(untilOutputFrom: isReady)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    publisher.send(1)
    publisher.send(2)
    publisher.send(3)
    
    /*:
     publisher会依次发布`isReady`开始发布数据之前的所有数据（1、2、3），
     但是这之后的数据将会被丢弃，通过`cancel`来结束该publisher的状态
     */
    isReady.send(100)
    
    publisher.send(4)
    publisher.send(5)
}

/*:
 从上面可以看出来，`first`和`last`是两个对立的操作符，`drop`和`prefix`也是两个对立的操作符，
 同样的他们都有相同的变种。
 */


//: [Next](@next)
