//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"
var subscriptions = Set<AnyCancellable>()

example(of: "") {
    /*:
     我们知道操作符所返回的都是一个个的结构体的实例，
     因此当将Publisher通过参数传入函数的时候，是值引用，
     swift会对Publisher进行copy，
     当每订阅一次，Publisher都会分发一次数据。
     
     接下来，我们来验证这个论点，每个Publisher都可以被任意多个Subscriber订阅，
     我们以为的是，Publisher只会分发一次数据，给到多个订阅者，但真实情况却不是这样的。
     */
    
    let arrayPub = [1,2,3,4]
        .publisher
        .print("array")
        .share()
    
    arrayPub
        .sink { print("1 value \($0)") }
        .store(in: &subscriptions)
    
    arrayPub
        .sink { print("2 value \($0)") }
        .store(in: &subscriptions)
    
    /*:
     上面的代码，我们创建了一个Publisher，然后为其添加了两个订阅者，对应的控制台输出为：
     
     ```
     array: receive subscription: ([1, 2, 3, 4])
     array: request unlimited
     array: receive value: (1)
     1 value 1
     array: receive value: (2)
     1 value 2
     array: receive value: (3)
     1 value 3
     array: receive value: (4)
     1 value 4
     array: receive finished
     #####
     array: receive subscription: ([1, 2, 3, 4])
     array: request unlimited
     array: receive value: (1)
     2 value 1
     array: receive value: (2)
     2 value 2
     array: receive value: (3)
     2 value 3
     array: receive value: (4)
     2 value 4
     array: receive finished
     ```
     可以看出来，`#####`上下两部分其实是一样的日志，Publisher分发数据、Subscriber订阅收到数据，
     也就是说，`arrayPub`其实是分发了两次。
     
     上面的这个应用场景多分发两次是没有问题的，
     但是如果是网络请求的Publisher，则会导致多次的网络请求，
     这显然不是我们想要的效果。
     
     这就是`shared()`操作符所要解决的问题。
     
     为`arrayPub`使用`shared()`来处理一下，然后看下控制台输出为：
     
     ```
     array: receive subscription: ([1, 2, 3, 4])
     array: request unlimited
     array: receive value: (1)
     1 value 1
     array: receive value: (2)
     1 value 2
     array: receive value: (3)
     1 value 3
     array: receive value: (4)
     1 value 4
     array: receive finished
     ```
     
     第二个订阅者，并没有收到分发的数据。
     
     这是怎么回事儿呢？
     
     
     */
}

example(of: "shared()") {
    return
    let shared = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.baidu.com")!)
        .map(\.data)
        .print("shared")
        .share()

    shared.sink { (_) in }
        receiveValue: {
            print("1 \($0.count)")
        }
        .store(in: &subscriptions)
    shared.sink { _ in }
        receiveValue: {
            print("2 \($0.count)")
        }
        .store(in: &subscriptions)
    
    /*:
     为一个网络请求的Publisher使用`shared()`操作符会发现，请求只发送了一次。
     
     */
}


example(of: "shared() asyncAfter") {
    
    return
    /*:
     如果第二个订阅者要很久之后才会去订阅，而这个时候请求其实已经完成了，
     这个时候会怎样呢？
     
     通过下面的例子，我们可以看到，在预订的时间点，
     Publisher已经分发了完成，所以第二个订阅者并不会受到分发的消息，
     只会收到一个completion消息。
     
     那要如何解决这种问题呢？
     */
    let shared = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.baidu.com")!)
        .map(\.data)
        .print("shared")
        .share()

    shared.sink { (_) in }
        receiveValue: {
            print("1 \($0.count)")
        }
        .store(in: &subscriptions)
    
    var subscription2 : AnyCancellable? = nil
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        subscription2 = shared.sink { _ in print("2 comp ")}
            receiveValue: {
                print("2 \($0.count)")
            }
    }
}

example(of: "multicast(_:)") {
    /*:
     当一个Publisher已经完成了分发，这个时候再为其添加一个订阅者，
     可能需要使用`replay`这样的操作符，但是Combine中并不存在这个操作符。
     
     multicast(_:)操作符返回的是一个`ConnectablePublisher`，
     它不会分发Publisher的数据，直到调用了`connect()`。
     
     `connect()`还有一个变形方法:`autoconnect()`，他和`shared()`类似，
     只要添加了一个Subscriber，就开始分发数据，并不符合这里的应用场景。
     
     */
    
    let subject = PassthroughSubject<Data, URLError>()
    
    let multicasted = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.baidu.com")!)
        .map(\.data)
        .print("multicast")
        .multicast(subject: subject)

    multicasted.sink { (_) in }
        receiveValue: {
            print("1 \($0.count)")
        }
        .store(in: &subscriptions)
    
    var subscription2 : AnyCancellable? = nil
    
    multicasted.sink { _ in print("2 comp ")}
        receiveValue: {
            print("2 \($0.count)")
        }
        .store(in: &subscriptions)
    multicasted.connect()
}

example(of: "multicast(_:)") {
    
    let subject = PassthroughSubject<String, Never>()
    
    let multicasted = ["hello world"]
        .publisher
        .print("multicast")
        .multicast(subject: subject)
    
    multicasted.sink {
        print("1 multicasted \($0)")
    }
    .store(in: &subscriptions)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        multicasted.sink {
            print("2 multicasted \($0)")
        }
        .store(in: &subscriptions)
        
        multicasted.connect()
    }
    
    /*:
     `multicast(_:)`需要配合着`connect()`使用，
     从multicast的源码可以看到，其内部其实是使用`Subject`来作为中间者，
     使用Subject对所有的订阅者进行分发，而Subject则作为上游Publisher的唯一订阅者接收数据。
     在使用`connect`的时候，上游Publisher才开始将中间者的Subject作为添加为订阅者，
     也就是在这个时候，上游Publisher才会分发数据，而Subject只是作为一个转发，转发给所有的订阅者。
     
     这就是multicast的实现原理。
     */
}

example(of: "Future") {
    
    let futuer = Future<Int, Never> { fulfill in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            fulfill(.success(100))
        }
    }
    .print("Future")
    
    futuer.sink { _ in
        print("Future comp")
    } receiveValue: {
        print("Future value \($0)")
    }
    .store(in: &subscriptions)

    futuer.sink { _ in
        print("Future comp 2")
    } receiveValue: {
        print("Future value 2 \($0)")
    }
    .store(in: &subscriptions)

}
//: [Next](@next)
