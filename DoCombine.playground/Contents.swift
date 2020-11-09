import UIKit
import Combine

var str = "Hello, playground"

public func example(of description: String, action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

let center = NotificationCenter.default
let noti = Notification.Name("something")
var subscriptions = Set<AnyCancellable>()

example(of: "Normal-Notification") {
    
    /// 常规的使用通知
    /// 1.在对特定通知感兴趣的地方添加观察者
    let observer = center
        .addObserver(forName: noti, object: nil, queue: nil) { notifaction in
        print("Normal receive notification:",notifaction)
    }
    
    /// 2.在某些时刻发送通知
    center.post(name: noti, object: nil)
    
    /// 3.合理的对通知进行添加和移除
    center.removeObserver(observer)
}

example(of: "Combine-Notification") {
    
    /// 使用Combine的方式来发通知
    /// 1.通过通知中心、通知获取一个Publisher
    let publisher = center.publisher(for: noti)
    
    /// 2.为这个Publisher添加一个订阅者，以及收到消息之后的回调
    let subscription = publisher.sink { notification in
        print("Combine receive notification:", notification)
    }
    
    /// 3.和往常一样，通知中心发送通知
    center.post(name: noti, object: nil)
    
    /// 4.订阅者取消订阅
    subscription.cancel()
}

example(of: "sink") {
    
    /// 通过Just可以获得到一个原始数据的Publisher，Just是内置的一个Publisher
    let just = Just("Hello world")
    
    /// sink是框架内置的可以便利生成一个订阅者的方法
    just.sink(receiveCompletion: { _ in
        print("Just completion")
    }) {
        print("Just receive value:",$0)
    }
    
    /// 任意一个Publisher都可以被一个或者多个订阅者订阅
    just.sink { text in
        print("Just receive other vaue:\(text)")
    }
}

example(of: "assign(to:on:)") {
    /// assign是框架内置的另一个便利生成订阅者的方法，他可以将数据和class的属性进行绑定
    class MyClass {
        var name: String = "" {
            /// 重写name的set方法，获取修改name时候的数据
            didSet {
                print(name)
            }
        }
    }
    
    let myObj = MyClass()
    
    /// 通过为数组提供的拓展，方便的生成一个Publisher
    let publisher = ["rocky","yh"].publisher
    
    /// 将publisher产生的数据绑定到myObj的name属性上
    publisher.assign(to: \.name, on: myObj)
}

example(of: "assign(to:)") {
    
    /// 和assign(to: on:)所不同的是，这个方法没有on，也就是说没有指明是哪一个对象
    /// 但其实是指明对象、属性都在to中做了，不过是使用了一些语法糖而已
    
    class MyClass {
        @Published var name = ""
    }
    
    let myObj = MyClass()
    
    /// 由于name属性使用了@Published来修饰，所以name本身就会成为一个Publisher，
    /// 在它的值发生变化的时候，作为Publisher会发送数据出去
    /// 会发现这里使用的是`$`符号，使用$的意思是获取到name的Publisher，
    /// 如果不使用$，那么name就是一个普通的属性而已
    myObj.$name
        .sink { newName in
            print("myObj did change name:\(newName)")
    }
    
    /// 下面为name的值做修改
    /// 1.原始的赋值操作
    myObj.name = "rocky"
    
    /// 2.使用一个Publisher改变name，这个方法已经废弃了
///    Just("yh")
///        .assign(to: &myObj.$name)
    
    /// 就简洁性上来说，还是直接赋值好些
}

example(of: "Cancellable") {
    /// 当一个订阅者完成了订阅，并且不需要再接受Publisher的数据时，可以对其进行cnacel
    
    /// 会发现，sink(receive...)相关的接口都是返回一个遵守`AnyCancellable`协议的对象
    let subscriptions = Just("hello").sink { (text) in
        print("receive text:\(text)")
    }
    /// 这个协议有一个cancel()方法，可以用来对订阅者进行取消订阅
    subscriptions.cancel()
    
    /// 同样的assign(to:...)系列的方法也是返回一个`AnyCancellable`
}

example(of: "Publisher & Subscriber 协议") {
    /// Publisher协议中除了Output、Failure之外，还有一个receive(_:)方法，
    /// 拓展方法里面还有一个subscribe(_:)方法，他们两个都是接受一个subscriber
    
    let publisher = Just("aaa")
    
    /// Subscriber 协议中有一系列的receive方法，他们的调用方是Publisher
    /// Publisher通过调用receive(..)方法来捕获数据
    
    /// Publisher和Subscriber之间的联系是Subscription，
    /// Publisher产生Subscription给Subscriber，
    /// 它只是一个协议
}

example(of: "Custom Subscriber") {
    
    let publisher = (1...9).publisher
    
    /// 创建一个类，遵守Subscriber协议
    final class IntSubscriber: Subscriber {
        /// 指定Input和Failure
        typealias Input = Int
        typealias Failure = Never
        
        /// 重写receive的三个方法
        /// 这个方法会被Publisher调用，
        func receive(subscription: Subscription) {
            /// 调用request、.max的意思是只接受3次数据
            /// Demand是定义在Subscribers命名空间下的，一般有unlimited、none、max
            subscription.request(.max(3))
        }
        /// 这个方法和上面的类似，只不过这里是直接返回了Demand
        /// 上一个方法设置了max(3)之后，这里设置unlimited和max(任意数字)，
        /// 会接受所有数据，也就是说，设置的max(3)无效
        /// 但是如果设置了none，max(3)就有效
        /// 这是因为只要不是none，在收到数据之后，max都会加1
        func receive(_ input: Int) -> Subscribers.Demand {
            print("receive value:\(input)")
            return .none
        }
        func receive(completion: Subscribers.Completion<Never>) {
            print("receive completion")
        }
    }
    
    let subscriber = IntSubscriber()
    
    publisher.subscribe(subscriber)
    
}

example(of: "Future") {
    
    /// Future是在Publishers命名空间中定义的
    /// 他可以使用于异步调用中，在异步中产生数据、完成
    
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
        
        /// Future本身也是遵守Publisher协议的
        /// Future内置了一个Promise类型的函数，这个函数接收的是Result类型的
        /// Promise的定义：`typealias Promise = (Result<Output, Failure>) -> Void`
        /// 而Result本身是swift中抽象结果的枚举，包括success和failure两个case
        /// Future的初始化也很简单，使用了一个尾闭包来创建即可，闭包就是上面提到的Promise函数
        Future<Int, Never> { promise in
            /// 闭包内部是创建一个延时异步线程的回调
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                /// 在回调中将数据交给promise
                promise(.success(integer + 1))
            }
        }
    }
    
    let future = futureIncrement(integer: 1, afterDelay: 1)
    
    /// 下面就来使用下这个Future
    futureIncrement(integer: 1, afterDelay: 1)
        .sink { value in
            print(value)
    }
    
    /// 上面这样写是不行的，由于这是一个异步操作，需要将subscription存储起来
    future
        .sink(receiveCompletion: { print($0) }) { print($0) }
        .store(in: &subscriptions)
    
    /// 再写一个订阅，会发现，两个订阅者收到的是相同的值
    /// 这说明，Future并没有重复执行promise，而是共享了状态
    future
        .sink(receiveCompletion: { print("second",$0) }) { print("second",$0) }
        .store(in: &subscriptions)
}

example(of: "Subject") {
    /// Subject 作为一个中间人角色，使得非Combine代码可以拥有Publisher的能力
    /// Subject有两个具体的子类：PassthroughSubject、
    
    enum MyError: Error {
        case one
    }
    
    
}
