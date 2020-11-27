//: [Previous](@previous)

import Foundation
import Combine
import UIKit

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
 
 我们知道可以使用通知中心的`addObserver(forName:,object:,queue:,using:)`方法来添加观察者，这样在block参数中就可以对收到的通知进行具体的业务处理了，同时返回的observation可以在适当的时候进行取消订阅。而在这个自定义的Subscription的构造方法中，通过这个方法来进行通知观察者的添加以及数据转换的。
 
 
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
 在初始化的时候，会默认demand为`.max(0)`，等同于`.none`，然后在回调中，每收到一次通知，demand就会自减一次。
 
 > 这里有个疑问，demand初始化的时候为0，这样并不会走到任何一个`if demand > 0`的true分支中，也就并不会对Subscriber传递数据了，这是怎么回事，不应该将demand初始为`.unlimited`么？
 >
 > 这个应该是安全处理。想象一下，如果设置了`.unlimited`，那么在Subscriber的`receive(subscription:)`方法中，如果不使用subscription调用它的`request(_:)`方法，那是不是就意味着，可以无限制的分发数据了？这样就相当于替使用者(Subscriber)做了决策，而正确的做法是应该将决策交给使用者自己。
 
 我们知道在Publisher收到数据的时候，会调用Subscriber的`receive(_:)`方法，将最新的数据分发给它。同时Subscriber还可以返回一个`Subscribers.Demand`，也就是上面的4处，Subscription会根据这个`additionalDemand`来决定是否要更新自己的demand。
 
 为了确保demand和observation是线程安全的，对他们的操作会加锁以确保安全，也就是上面的1和5处。以上就是构造函数中的核心方法。
 
 Subscription本身是一个协议，其有一个`func request(_ demand: Subscribers.Demand)`方法需要实现。并且该方法可以在Subscriber的`receive(subscription:)`方法中调用，让具体的Subscriber来决定其可以接受数据的次数限制，一般来说，如果没有什么特殊的要求，都会传递`.unlimited`，系统的Sink实现也是这样的。另外通过`.print()`查看很多系统拓展可以发现的，比如一开始的控制台输出为：
 
 ```
 receive subscription: (SomeCustomSubscriptionName)
 request unlimited
 ```
 
 在`request(_:)`方法中会更新demand，根据传递的Demand值作为demand的增量，这样和通知的回调中的逻辑一起，就组成了通过demand来限制数据的分发次数的逻辑。
 
 ```swift
 func request(_ d: Subscribers.Demand) {
     lock.lock()
     demand += d
     lock.unlock()
 }
 ```
 
 我们知道，Subscription协议本身还继承了`Cancellable`协议，所以他也具备`cancel()`功能，在cancel功能中要做的就是移除对应通知的订阅，安全的销毁一些变量等操作。
 
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
 
 ### KVC
 
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
 
 这部分将会对系统已经提供的一些操作符进行拓展，由于有些操作符本身具有的限制，所以为了应对更加多变的业务需求，对这些操作符进行拓展是一个比较明智的选择。
 
 ### assign 1
 
 系统提供了`assign`可以方便的完成订阅，但是目前只支持将数据绑定到一个class上，如果有两个或者多个地方需要绑定，就没有办法了，这个时候就需要拓展assign操作符。
 
 可以转换思路，通过`sink`操作符，在其回调中拿到分发的数据，然后将数据赋值给对应的实例即可，这样就变相的实现了多对象的绑定了。
 
 比如下面的示例：
 */

class Car {
    var money: Int = 0
}

class Person {
    var age: Int = 0
}

var aCar = Car()
var bPerson = Person()

let aPublisher = PassthroughSubject<Int, Never>()

_ = aPublisher.sink {
    aCar.money = $0
    bPerson.age = $0
}

aPublisher.send(30)

print(aCar.money)// 30
print(bPerson.age)// 30


/*:
 
 内部使用sink，只要提供和assign类似的api即可了，同时借助于`KVC`，可以很方便的将对应的数据更新到实例上，以此类推，可以拓展出任意数量的assign操作符。
 
 */
public extension Publisher where Self.Failure == Never {
    
    func assign<Root1, Root2>(to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
                              and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2) -> AnyCancellable {
        sink(receiveValue: { value in
            object1[keyPath: keyPath1] = value
            object2[keyPath: keyPath2] = value
        })
    }
}

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

 ### assign 2
 
 swift和Objective-C一样，都是使用[Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID52)来管理内存的使用，我们知道为了解决循环引用问题，在swift中可以使用week、unowned来打破引用环。
 
 `weak`和Objective-C中的一样，对其引用的实例不进行强持有，当ARC引用的实例被释放时，ARC会自动将弱引用设置为nil。而且，因为弱引用需要允许它们修饰的值在运行时被更改为nil，所以它们应该被声明为`可选类型`的变量。

 `unowned`与weak一样，它也不会对它引用的实例强持有。然而，与weak不同，unowned比其修饰的实例具有相同或更长的生存期，无主引用应该总是有一个值。因此，将一个值标记为无主并不意味着它是可选的，而且ARC从不将unowned修饰的实例设置为nil。
 
 而`assign(_:)`操作符默认是使用的strong，也就是强引用。因此如果使assign支持弱引用，可以和上面一样，使用`sink`和`KVO`来完成。
 
 */
public enum ObjectOwnership {
    case strong
    case weak
    case unowned
}

public extension Publisher where Self.Failure == Never {
    
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
                                 on object: Root,
                                 ownership: ObjectOwnership = .strong) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath, on: object)
        case .weak:
            return sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
        case .unowned:
            return sink { [unowned object] value in
                object[keyPath: keyPath] = value
            }
        }
    }
}

/*:
 
 ### zip
 
 目前Combine内置的`zip`操作符最多只支持2个Publisher的组合操作。从其代表的`拉链`的角度来看，也许现实中不会有3个链条进行咬合，但是对业务开发中还是有可能需要2个或者多个Publisher进行组合操作，对zip提供可以使用`装载着Publisher的数组`来组合多个Publisher是一个拓展方向。
 
 从前面我们知道`reduce()操作符`可以对多个Publisher进行增量操作，并且会将最终结果进行分发。同样的在swift的基础库中，对Sequence来说也有一个`reduce函数`，他们两者的作用是一样的，都是对增量的处理。
 
 因此可以结合这个函数和`zip()`操作符，来完成一个多Publisher的zip。将源Publisher作为`initialResult`，然后对要zip的多个Publisher（这里使用`Collection`的形式）进行增量处理，同时自定义增量规则，将每次增量的结果和下一个要计算的Publisher进行zip操作，具体实现如下：
 
 */

public extension Publisher {
    
    func zip<Others: Collection>(with others: Others)
        -> AnyPublisher<[Output], Failure>
        where Others.Element: Publisher, Others.Element.Output == Output, Others.Element.Failure == Failure {
        let seed = map { [$0] }.eraseToAnyPublisher()
        return others
            .reduce(seed) { zipped, next in
                zipped
                    .zip(next)
                    .map { $0.0 + [$0.1] }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

let cPublisher = PassthroughSubject<Int, Never>()

let dPublisher = PassthroughSubject<Int, Never>()
let ePublisher = PassthroughSubject<Int, Never>()
let fPublisher = PassthroughSubject<Int, Never>()


let aaa = [1,2,3,]
    .reduce(100) { zipped, next in
        zipped + next
}

//_ = [dPublisher,dPublisher,fPublisher]
//    .reduce(cPublisher) { zipped, next in
//        zipped
//            .zip(next)
//            .map{ $0.0 + [$0.1] }
//            .eraseToAnyPublisher()
//    }

cPublisher
    .zip(with: [dPublisher, ePublisher, fPublisher])
    .sink { values in
        print("values: \(values)")
}

cPublisher.send(1)
cPublisher.send(11)
cPublisher.send(111)

dPublisher.send(2)

ePublisher.send(3)
fPublisher.send(4)

dPublisher.send(22)
ePublisher.send(33)
fPublisher.send(44)

/*:
 
 ### combineLatest
 
 前面我们知道，`combineLatest(_:)`操作符可以将多个publisher的最新数据进行整合，然后将组合好的数据进行分发，经过这样的操作，就可以保证所有分发者的数据都是最新的，整合后的数据会默认会被当做元组进行分发。
 
 那么如果想要将元组类型换成数组类型，要如何操作呢？
 
 同样借助于`reduce函数`和`combineLatest()操作符`，将增量的结果和后面的Publisher进行combineLatest组合，然后将要分发的数据转化成数组，具体代码如下：
 
 */

public extension Publisher {
    
    func combineLatest<Others: Collection>(with others: Others)
        -> AnyPublisher<[Output], Failure>
        where Others.Element: Publisher, Others.Element.Output == Output, Others.Element.Failure == Failure {
            let seed = map { [$0] }.eraseToAnyPublisher()
            
            return others.reduce(seed) { combined, next in
                combined
                    .combineLatest(next)
                    .map { $0 + [$1] }
                    .eraseToAnyPublisher()
            }
    }
}

/*:
 
 ## 自定义操作符
 
 接前篇，这一篇将会主要讨论学习如何如自定义操作符，主要分为创建RxSwift中有但是Combine中没有的操作符，以及为UIControl拓展对应的操作符，最后介绍一下对于已有项目如何进行Combine-like的改造。
 
 ### withLatestFrom
 
 [`withLatestFrom`](https://github.com/ReactiveX/RxSwift/blob/78f2dd64f12c09b5bc31ef719e55b1a4c4da0d3d/RxSwift/Observables/WithLatestFrom.swift)是一个和`combineLatest`类似的操作符，所不同的是，使用了该操作符的Publisher只关心当前分发者的最新数据，以及最新数据来的时候(称作`时刻1`)要组合的另一个Publisher的最新数据之间的组合，在`时刻1`来之前，无论另一个Publisher分发多少数据，都只使用它最新最近的一个数据，结果也是以元组的形式向下游分发。
 
 ![withLatestFrom](https://ficowblog.oss-cn-shenzhen.aliyuncs.com/uploads/1601165126785.png)
 
 有了操作符的意义，下面就可以开始实现这个操作符。
 */

/*:
 
 ### UIControl
 
 从前面拓展NotificationCenter我们知道拓展的一般流程，这里是要拓展UIControl，所以需要一个中间类来作为UIControl的target，也就是Subscription。自定义一个Subscription，使其作为Publisher和Subscriber之间的
 
 */

extension UIControl {

    public struct Publisher<Control: UIControl>: Combine.Publisher {
        
        public typealias Output = Control
        public typealias Failure = Never
        
        public let control: Control
        public let event: UIControl.Event
        
        init(control: Control, event: Control.Event) {
            self.control = control
            self.event = event
        }
        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(
                subscription: UIControl.Inner(subscriber, control, event)
            )
        }
    }
}
extension UIControl {

    final class Inner<S: Subscriber, Control: UIControl>: Subscription where S.Input == Control, S.Failure == Never {
        
        private var subscriber: S?
        private let control: Control
        private let event: Control.Event
        
        init(_ subscriber: S, _ control: Control, _ event: Control.Event) {
            self.subscriber = subscriber
            self.control = control
            self.event = event
            
            control.addTarget(self, action: #selector(onAction), for: event)
        }
        
        func request(_ demand: Subscribers.Demand) {
            
        }
        
        func cancel() {
            subscriber = nil
            control.removeTarget(self, action: #selector(onAction), for: event)
        }
        
        // MARK: Action
        
        @objc private func onAction() {
            subscriber?.receive(control)
        }
    }
}

extension UIControl {
    func publisher(for event: UIControl.Event) -> UIControl.Publisher<UIControl> {
        .init(control: self, event: event)
    }
}
extension UISwitch {
    func publisher() -> AnyPublisher<Bool, Never> {
        UIControl.Publisher(control: self, event: .valueChanged)
            .map { $0.isOn }
            .eraseToAnyPublisher()
    }
}

extension UITextField {
    func pulisherForTextChanged() -> AnyPublisher<String?, Never> {
        UIControl.Publisher(control: self, event: .editingChanged)
            .map { $0.text }
            .eraseToAnyPublisher()
    }
}

extension UISlider {
    func publisher() -> AnyPublisher<Float, Never> {
        UIControl.Publisher(control: self, event: .editingChanged)
            .map { $0.value }
            .eraseToAnyPublisher()
    }
}

let button = UIButton()
button.setTitle("Tap me", for: .normal)
button.frame = .init(x: 0, y: 0, width: 100, height: 40)

button.publisher(for: .touchUpInside)
    .sink { print("\($0)") }


class MyViewModel: NSObject {
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    var vaildToRegisterPublisher : AnyPublisher<Bool, Never> {
        // 整合Publisher，将数据处理成最终需要的类型
        Publishers.CombineLatest3($name, $password, $confirmPassword)
            .map { (name, password, confirmPassword) -> Bool in
                name.count > 6 &&
                    password.count > 6 &&
                    password.count < 15 &&
                    password == confirmPassword
        }.eraseToAnyPublisher()
    }
}

let onePublisher = PassthroughSubject<Int, Never>()
let otherPublisher = PassthroughSubject<String, Never>()

onePublisher
    .combineLatest(otherPublisher)
    .sink { (one, other) in
        print("one value: \(one) , other value: \(other)")
}

onePublisher.send(1)
onePublisher.send(2)

otherPublisher.send("a")

otherPublisher.send("a")

/*:
 * [CombineExt](https://github.com/CombineCommunity/CombineExt)
 * [Combine vs RxSwift](https://quickbirdstudios.com/blog/combine-vs-rxswift/)
 * [RxSwift to Combine cheatsheet](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet)
 * [如何创建自定义的 Combine 操作符？](https://blog.ficowshen.com/page/post/32)
 * [携程-深入浅出Apple响应式框架Combine](https://mp.weixin.qq.com/s/8LErZWJ0F0VsZ7WgjCb-Vg)
 */
//: [Next](@next)
