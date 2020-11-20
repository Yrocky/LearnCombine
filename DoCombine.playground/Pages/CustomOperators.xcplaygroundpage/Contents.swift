//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

/*:
 
 ## 引子
 
 从[RxSwift和Combine的对比](https://quickbirdstudios.com/blog/combine-vs-rxswift/)来看，Combine在性能上是优于RxSwift的，可能和官方内部使用了一些编译器优化有关。但是本文不关注两者在性能上的优劣，一个响应式框架是否受欢迎，其所提供的操作符的多少也是其中一个重要的指标，从[这里](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet)可以看出来，Combine相对于RxSwift来说，其支持的操作符数量还是有点儿少的，并且一些已经支持的操作符还会和RxSwift有所差异。
 
 基于Combine提供了很多基础协议以及类，所以我们还是可以很方便的根据响应式框架思想提出的操作符概念，来自定义实现的。下面将会在Combine框架的基础上，对自定义操作符进行一下探讨学习。首先会从基础的Publisher和Subscriber入手，之后看下Combine是如何对已有框架进行拓展的，接着尝试对已经提供的操作符进行改进，最后尝试实现RxSwift提供但是Combine中没有提供的操作符，以及对UIControl进行拓展。
 
 here we go!
 
 ## Publisher Subscriber
 
 我们前面提到过Publisher和Subscriber之间是如何传递数据的。
 
 Publisher通过调用`subscribe(_:)`和Subscriber进行绑定，然后Publisher内部会调用Subscriber的`1️⃣receive(subscription:)`方法，传递给Subscriber一个`Subscription实例`，它可以使用这个Subscription实例，比如，通过它的`request(_:)`方法可以来决定接收数据的次数限制。
 
 当用户产生了数据，Publisher会通过Subscription调用Subscriber的`2️⃣receive(_:)`方法，需要注意的是，该方法有可能是`异步调用`，然后根据该方法的返回值决定是否要产生一个新的Publisher。同时，还可以返回一个`Subscribers.Demand`类型来更改接收数据的次数限制。
 
 一旦Publisher停止发布（发送一个Completion数据），就会调用Subscriber的`3️⃣receive(completion:)`方法，参数是一个`Completion`枚举，有可能是`完成`，也有可能有一个`错误`。
 
 ![p-2-s](https://assets.alexandria.raywenderlich.com/books/comb/images/9f8c264464ac8f521e79ca6b467112bf760c8252e4f01777f9f5aff7ec4087d9/original.png)
 
 可以看出来，`Subscrption`是链接Publisher和Subscriber的桥梁，没有它Combine事件流无法驱动。
 
 ## Combine提供的拓展
 
 Combine虽然是闭源的，但是其对[URLSession](https://github.com/apple/swift/blob/aa3e5904f8ba8bf9ae06d96946774d171074f6e5/stdlib/public/Darwin/Foundation/Publishers%2BURLSession.swift)、[NotificationCenter](https://github.com/apple/swift/blob/aa3e5904f8ba8bf9ae06d96946774d171074f6e5/stdlib/public/Darwin/Foundation/Publishers%2BNotificationCenter.swift)、[KeyValueObserving](https://github.com/apple/swift/blob/aa3e5904f8ba8bf9ae06d96946774d171074f6e5/stdlib/public/Darwin/Foundation/Publishers%2BKeyValueObserving.swift)、[Timer](https://github.com/apple/swift/blob/aa3e5904f8ba8bf9ae06d96946774d171074f6e5/stdlib/public/Darwin/Foundation/Publishers%2BTimer.swift)、[Locking](https://github.com/apple/swift/blob/aa3e5904f8ba8bf9ae06d96946774d171074f6e5/stdlib/public/Darwin/Foundation/Publishers%2BLocking.swift)等的拓展是开源的，通过这些开源拓展的实现，我们可以了解Combine是如何对已有框架进行改进的，这可以为我们对自己或者常用的框架进行Combine-like的修改提供学习模板。
 
 ### NotificationCenter
 
 首先看下对`NotificationCenter`的拓展，这个也是官方解释Combine的时候使用的第一个类：
 
 ```swift
 
 let center = NotificationCenter.default
 let noti = Notification.Name("something")

 //: 1.通知中心通过通知获取一个Publisher
 let publisher = center.publisher(for: noti)
 
 //: 2.为这个Publisher添加一个订阅者，以及收到消息之后的回调
 let subscription = publisher.sink { notification in
     print("Combine receive notification:", notification)
 }
 
 //: 3.和往常一样，通知中心发送通知
 center.post(name: noti, object: nil)
 
 //: 4.订阅者取消订阅
 subscription.cancel()
 ```
 
 从源码中可以看到，为NotificationCenter拓展的`publisher(for:,object:)`方法返回的是一个Output为`Notification`，Failure为`Never`的`NotificationCenter.Publisher`，其最重要的`receive(_:)`方法的实现如下：
 
 ```swift
 public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
     subscriber.receive(subscription: Notification.Subscription(center, name, object, subscriber))
 }
 ```
 
 这里使用了一个自定义的Subscription：`Notification.Subscription`来完成数据的流动，构造方法需要`NotificationCenter`、`Notification.Name`、可选的`object`以及下游的订阅者`next`。
 
 我们知道可以使用通知中心的`addObserver(forName:,object:,queue:,using:)`方法来添加观察者，这样在block参数中就可以对收到的通知进行具体的业务处理了。而在这个自定义的Subscription中也是在构造方法中，通过这个方法来进行通知观察者的添加以及数据转换的。
 
 
 ```swift
 // in init
 self.observation = center.addObserver(
     forName: name,
     object: object,
     queue: nil
 ) { [weak self] note in
     guard let self = self else { return }

     // 1.
     self.lock.lock()
     guard self.observation != nil else {
         self.lock.unlock()
         return
     }

     // 2.
     let demand = self.demand
     if demand > 0 {
         // 3.
         self.demand -= 1
     }
     self.lock.unlock()

     if demand > 0 {
         // 4.
         self.downstreamLock.lock()
         let additionalDemand = next.receive(note)
         self.downstreamLock.unlock()

         if additionalDemand > 0 {
             // 5.
             self.lock.lock()
             self.demand += additionalDemand
             self.lock.unlock()
         }
     } else {
         // Drop it on the floor
     }
 }
 ```
 在初始化的时候，会默认demand为`.max(0)`，等同于`.none`，也就是0次？，然后在回调中，每收到一次通知，demand就会自减一次。
 
 > 这里有个疑问，demand初始化的时候为0，这样并不会走到任何一个`if demand > 0`的true分支中，也就并不会对Subscriber传递数据了，这是怎么回事，不应该将demand初始为`.unlimited`么？
 >
 > 这个应该是安全处理。想象一下，如果设置了`.unlimited`，那么在Subscriber的`receive(subscription:)`方法中，如果不使用subscription调用它的`request(_:)`方法，那是不是就意味着，可以无限制的分发数据了？这样就相当于替使用者(Subscriber)做了决策，而正确的做法是应该将决策交给使用者自己。
 
 我们知道在Publisher收到数据的时候，会通过Subscription调用Subscriber的`receive(_:)`方法，将最新的数据分发给它。同时Subscriber还可以返回一个`Subscribers.Demand`，也就是上面的4处，Subscription会根据这个`additionalDemand`来决定是否要更新自己的demand。
 
 为了确保demand和observation是线程安全的，对他们的操作会加锁以确保安全，也就是上面的1和5处。
 
 以上就是构造函数中的核心方法，我们知道Subscription本身是一个协议，其有一个`func request(_ demand: Subscribers.Demand)`方法需要实现。该方法可以在Subscriber的`receive(subscription:)`方法中调用，让具体的Subscriber来决定其可以接受数据的次数限制，一般来说，没有什么特殊的要求，都会传递`.unlimited`，这也是通过`.print()`查看很多系统拓展，一开始的控制台输出为：
 
 ```
 receive subscription: (**SomeCustomSubscriptionName**)
 request unlimited
 ```
 
 在`request(_:)`方法中，会更新demand，让其自增一次，这样和通知的回调中的逻辑一起，就组成了通过demand来限制数据的分发次数的逻辑。
 
 ```swift
 func request(_ d: Subscribers.Demand) {
     lock.lock()
     demand += d
     lock.unlock()
 }
 ```
 
 我们知道，Subscription协议本身还继承了`Cancellable`协议，所以他也具备`cancel()`功能，在cancel功能中要做的就是移除对应通知的订阅，安全的销毁一些变量。
 
 ```swift
 func cancel() {
     lock.lock()
     guard let center = self.center,
         let observation = self.observation else {
             lock.unlock()
             return
     }
     self.center = nil
     self.observation = nil
     self.object = nil
     lock.unlock()

     center.removeObserver(observation)
 }
 ```
 
 以上就是系统如何拓展NotificationCenter的详细解释，总的来说就是：
 
 * 将自定义Subscription作为异步操作的真实发起者
 * 在具有异步操作的回调中，根据demand来决定是否要将数据分发给Subscriber
 * 在request方法中更新demand
 * 在cancel中移除监听以及一些变量数据
 
 需要注意的是在对数据处理的时候，使用lock以确保线程安全。
 
 ###
 
 
 
 
 
 
 */

let a = Subscribers.Demand.max(0)
let b = Subscribers.Demand.unlimited
let c = Subscribers.Demand.none

let result = a == 0

NotificationCenter.default
    .addObserver(forName: Notification.Name("something"), object: nil, queue: nil) { (noti) in
    
}
/*:
 
 ## 改进操作符
 
 */
public extension Publisher where Self.Failure == Never {
    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func assign<Root1, Root2>(to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
                              and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2) -> AnyCancellable {
        sink(receiveValue: { value in
            object1[keyPath: keyPath1] = value
            object2[keyPath: keyPath2] = value
        })
    }
}

class Car {
    var money: Int = 0
}

class Person {
    var age: Int = 0
}

var aCar = Car()
var bPerson = Person()

let aPublisher = PassthroughSubject<Int, Never>()

aPublisher.assign(to: \.money, on: aCar,
                  and: \.age, on: bPerson)

aPublisher.send(100)
print("aCar money \(aCar.money)");
print("bPerson age \(bPerson.age)");


var cCar = Car()

cCar[keyPath: \.money] = 200
//cCar[keyPath: "money"] = 300// no such subscripts

print("cCar money \(cCar.money)");


/*:
 
 ## 自定义操作符
 
 https://blog.ficowshen.com/page/post/32
 
 */
/*:
 * [CombineExt](https://github.com/CombineCommunity/CombineExt)
 * [Combine vs RxSwift](https://quickbirdstudios.com/blog/combine-vs-rxswift/)
 * [RxSwift to Combine cheatsheet](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet)
 * [携程-深入浅出Apple响应式框架Combine](https://mp.weixin.qq.com/s/8LErZWJ0F0VsZ7WgjCb-Vg)
 */
//: [Next](@next)
