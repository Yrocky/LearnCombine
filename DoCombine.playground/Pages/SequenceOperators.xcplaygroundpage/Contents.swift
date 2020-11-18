//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

public func example(of description: String, action: () -> Void) {
    
    print("\n--- Example of:", description, "---")
    action()
}

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

//: [Next](@next)
