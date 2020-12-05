//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

example(of: "DispatchQueue") {
    
    /*:
     
     正常情况下，我们的数据都是在main线程分发的，这很安全，也很方便，
     但是如果是网络请求，我们并不希望在主线程中进行，而是想要在异步线程中分发数据。
     除了主线程，还可以使用`DispatchQueue`来基于`global`开启异步线程。
     在Combine中也有类似的概念，那就是`Schedulers`，
     Combine提供了Schedulers，使得使用者很方便的在异步线程发起请求。
     */
    
    /*:
     `Scheduler`是一个协议，在分发系统中作为上下文来执行操作，
     提供调用的程序的执行时机，可以是立即、未来某个具体日期。
     在执行时间上，提供了很实际的粒度，都是基于现实计时系统的，使用`SchedulerTimeType`来抽象。
     在Combine中的定义说的是，可以选择一个时刻来执行一个`closure`，
     当然这里并不是指一个闭包，可以是上游发布者分发的某个具体的值。
     
     但是你会发现，定义中并没有提到任何一个关于线程的点，这是因为线程也是上下文的一部分，
     具体的实现才需要决定上下文要执行的位置（线程）。
     
     代码将要在哪个线程执行取决于选择的Scheduler，`线程并不等于Scheduler`。
     虽然Scheduler很依赖线程，并且可以选择串行还是并行执行，但两者并不是等同的概念。
     
     */

    /*:
     参考一个场景：
     用户点击Button，产生一个事件，这个事件在异步Scheduler经过转化，
     成为一个Bool值数据传递给最终的订阅者，订阅者收到之后更新对应的UI。
     
     这是一个典型的main产生事件，经过异步处理，最终回到main中更改ui的事件流。
     
     关于Scheduler有两个比较重要的操作符：`subscribe(on:)`、`receive(on:)`。
     */
    
    /*:
     
     前面我们知道，在Combine中，Publisher是通过`subscribe(_:)`来进行订阅的，通过该方法会产生一个`Subscription`。
     但还有一个变种的方法：`subscribe(on:)`，可以指定在何种调度器中创建Subscription。
     */
    
    let Sub = Subscribers.Sink<Int, Never>.init { _ in
        print("comp at \(Thread.current)")
    } receiveValue: {
        print("value: \($0) at \(Thread.current)")
    }

    let Pub = [99].publisher
    //: 使用`subscribe(_:)`进行订阅
    Pub.print("Pub").subscribe(Sub)
    
    /*:
     Publisher在被订阅之前一直是无生命的个体，通过`subscribe(_:)`添加订阅者，
     产生Subscription之后，一个Publisher才是活了起来，
     之后会将数据分发给订阅者。
     一般来说在调用`subscribe(_:)`地方是什么线程，
     之后的转化、分发、接收操作都是在这个线程中。
     而如果使用`subscribe(on:)`指定一个Scheduler，我们就可以在另一个线程进行之后的操作了。
     */
    
    let queue = DispatchQueue(label: "my serial queue")
    //: DispatchQueue已经支持了`Scheduler`协议
    Pub.print("Queue").subscribe(on: queue).subscribe(Sub)
}

extension Publishers {
    
    struct MyCustomPublisher: Publisher{
        
        typealias Output = Int
        typealias Failure = Never
    
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: Inner(subscriber))
            print("[Custom] receive \(subscriber) at \(Thread.current)")
        }
    }
    
    final class Inner<S: Subscriber>: Subscription where S.Input == Int, S.Failure == Never{
        
        fileprivate let subscriber: S
        init(_ subscriber: S) {
            self.subscriber = subscriber
        }
        
        func request(_ demand: Subscribers.Demand) {
            print("[Custom] request at \(Thread.current)")
        }
        
        func cancel() {
            print("[Custom] cancel at \(Thread.current)")
        }
    }
}

example(of: "receive(on:)") {
    /*:
     上面的是在指定的调度器中执行订阅，还可以使用`receive(on:)`在指定的调度器中分发数据。
     */
    
}
//: [Next](@next)
