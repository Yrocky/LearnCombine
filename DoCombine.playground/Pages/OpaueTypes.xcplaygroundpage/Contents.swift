//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

/*:
 
 ## 引子
 
 > `不透明类型`（Opaue Types）是swift中用来隐藏函数或者方法的返回值类型信息的特性，函数不再提供具体的类型作为返回类型，而是根据它支持的协议来描述返回值。
 
 从他的定义上来看，其和泛型有些相识，但其实它是用来应用于泛型所不能胜任的场景的。接下来我们会了解不透明类型与泛型之间的区别，另外会通过[CombineX](https://github.com/cx-org/CombineX)这个开源框架来探究学习下Combine是如何实现不透明类型的。
 
 here we go!
 
 ### 泛型和不透明类型
 
 我们知道泛型可以约束函数中的参数或者返回值，调用者可以通过提供具体的类型来决定运行时泛型的类型，比如下面的`printFirstThree`函数。
 
 */

func printFirstThree<S>(in sequence: S) where S: Sequence, S.Element == Int{
    print(sequence.first(where: { (value) -> Bool in
        value == 3
    }) as Any)
}

printFirstThree(in: [1,2,3,4,3,5])

/*:
 
 swift会对使用泛型约束的参数进行类型推断，也就是会根据具体的输入类型来决定泛型，因此上面的函数可以执行。但是如果我们仅仅约束返回值，并不约束参数，同样的还需要使用泛型，在我们调用函数的时候，由于没有隐式的声明泛型的类型，所以就需要显式的声明。
 
 */
func subSequenceLengthIsThree<S>() -> S where S: Sequence, S.Element == Int{
    return [1,2,3] as! S
}

/*:
 但是我们并不能显式的声明泛型，因为这样语法不正确，这个就是泛型所不足的地方。
 */

//let some = subSequenceLengthIsThree<Int>()

/*:
 不透明类型就是为了解决这种问题的，不透明类型做了泛型不能做的，其允许返回类型和函数无关，但是会与具体函数实现有关，这就是定义中所说的`隐藏函数或者方法的返回值类型的信息`。
 
 在swift中已经有很多的内置不透明类型，比如接下来要使用的`AnySequence`就是其中一个，我们可以使用他来改造上面的函数：
 */
func subSequenceLengthIsThree2() -> AnySequence<Int> {
    return AnySequence([1,2,3])
}
let array = subSequenceLengthIsThree2()

/*:
 使用了AnySequence会发现，整个函数不论是声明还是调用都是正确的。AnySequence其实是一个具体的结构体，其遵守`Sequence`协议，内部会通过一个私有的`box`属性来完成类型的隐藏、方法的传递，下面就是通过打印array获得的信息，并且在接下来的小节中我们会通过自定义不透明类型来验证这一点。
 
 ```swift
 AnySequence<Int>(_box: Swift._SequenceBox<Swift.Array<Swift.Int>>)
 ```
 不仅如此，在swift5.0之后，系统还提供了`some`关键字来表示类型擦除，这个就属于编译器优化了。与AnySequence等一系列的不透明类型类似，some可以对协议、基类、Any、AnyObject等进行修饰。
 
 */

func subSequenceLengthIsThree3() -> some Sequence {
    return Set([1,2,3])
}
let otherArray = subSequenceLengthIsThree3()

for value in array {
    print("value \(value)")
}

protocol Shape {
    associatedtype Output
}

struct Square: Shape {
    typealias Output = Int
}

func ssss() -> some Shape {
    Square()
}

/*:
 
 ### 协议类型和不透明类型
 
 通过上面我们发现不透明类型和协议类型很相似，但两者其实是有区别的：`是否需要保证类型一致性`。
 
 一个不透明类型只能对应一个具体的类型，即便函数调用者并不能知道是哪一种类型；协议类型可以同时对应多个类型，只要它们都遵循同一协议。总的来说，协议类型会更具灵活性，底层类型可以存储更多样的值，而不透明类型对这些底层类型有更强的限定。
 
 比如下面，我们可以很灵活的使用协议来完成一个函数，函数会返回不同类型的对象，这些对象或直接或间接和这个协议有关系：
 
 ```swift
 protocol Moveable {}
 protocol Runable: Moveable {}

 struct Car: Moveable {}
 struct Person: Runable {}

 func aMoveableCar () -> Moveable {
     if (someCondition) {
         return Car()
     }
     return Person()
 }
 ```
 
 看起来完全可以不使用不透明类型，但是如果你尝试去分别使用两次函数，并且将得到的数据进行比较，你会发现编译器给了你一个错误:
 
 ```swift

 let aCar = aMoveableCar()
 let aPerson = aMoveableCar()

 aCar == aPerson// Binary operator '==' cannot be applied to two 'Moveable' operands
 ```
 
 这是因为使用协议作为返回类型的函数，其真实返回类型是具有`不确定性`的，并不可以用来进行比较。当然如果尝试让`Moveable`继承`Equatable`协议并且实现`==`函数，让==两边的对象具备可以比较的能力，你会发现还是会报错。这是因为这类运算符会使用`Self`来作为参数来匹配符合协议的具体类型，但是，我们使用了协议对他们进行了类型擦除，并不知道是什么类型，所以就编译通过。
 
 协议类型虽然更灵活，但是这样也导致牺牲了对返回值执行某些操作的能力，这个能力恰恰是不透明类型具备的，并且不透明类型保留了底层类型的唯一性，Swift能够推断出其关联的类型。
 
 */

protocol Moveable {}
protocol Runable: Moveable {}

struct Car: Moveable {}
struct Person: Runable {}

let someCondition: Bool = false
func aMoveableCar () -> Moveable {
    if (someCondition) {
        return Car()
    }
    return Person()
}

let aCar = aMoveableCar()

let aPerson = aMoveableCar()

//aCar == aPerson


protocol MySequence{
    
}

class MyAnySequence<Element>{
    
    let sequence: MySequence
    
    init(_ sequence: MySequence) {
        self.sequence = sequence
    }
}

extension MyAnySequence: MySequence {
    
}
/*:
 
 ## Combine中的不透明类型
 
 在Combine中也有一些内置的不透明类型：`AnyPublisher`、`AnySubscriber`、`AnyCancelable`等，他们分别是对`Publisher`、`Subscriber`、`Cancelable`协议。
 
 在Combine中很多操作符都是使用具体的结构体实现的，比如Merge、Map、Sequence等等，有可能会有一个ViewModel的属性接收的是多个操作符处理之后的Publisher。这样就会造成一个困惑，我们不知道要怎么声明这个属性的类型，而基于不透明类型实现的`AnyPublisher`就可以解决这样的问题。
 
 */

class MyViewMode{
    
    var publisher: AnyPublisher<String, Never>
    
    init() {
        self.publisher = AnyPublisher<String, Never>(Just(""))
    }
    
    func fetchDefaultList() {
        self.publisher = ["a","b","c"]
            .publisher
            .replaceError(with: "error")
            .eraseToAnyPublisher()
    }
    
    func fetchNetworkList() {
        
        publisher = URLSession.shared
            .dataTaskPublisher(for: URL(string: "")!)
            .map{ _ in "" }
            .replaceError(with: "error")
            .eraseToAnyPublisher()
    }
}
/*:
 
 ### [AnyPublisher](https://github.com/cx-org/CombineX/blob/master/Sources/CombineX/AnyPublisher.swift)
 
 在上面`subSequenceLengthIsThree2`函数中，通过打印其返回值，我们知道其内部其实是一个`__SequenceBox`私有实例，然后这个`box`又包裹了`Array`，也就是具体的函数中返回的类型。下面我们根据这个思路来探究下Combine是如何实现AnyPublisher的。
  
 AnyPublisher其本身也是一个Publisher，本质就是将自己作为要包装的Publisher来使用，内部使用一个私有的`Box`类用来完成包装。由于实现了Publisher协议的的`receive`方法，所以在这里需要将对应的数据交给被包装的Publisher。
 
 使用一个私有的Box可以隐藏一些实现细节，首先我们先创建这个类：
 
 ```swift
 class PublisherBaseBox<Output, Failure: Error>: Publisher {
     
     func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
         // do nothing
     }
 }
 class PublisherBox<Base: Publisher>: PublisherBaseBox<Base.Output, Base.Failure> {
     
     let base: Base
     
     init(_ base: Base){
         self.base = base
     }
     
     override
     func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input{
         self.base.receive(subscriber: subscriber)
     }
 }
 ```
 这里我们创建了两个Box类，并且他们还是继承关系，这样我们可以在不暴露类型信息的情况下从多个类型中包装一些公共的功能，这也是类型擦除在类中的应用，这一点很像类簇。
 
 然后我们创建自己的`MyAnyPublisher`，在这里使用`PublisherBaseBox`来作为声明，但是具体的实现使用`PublisherBox`，这样如果以后要加入对其他类型的包裹，还可以使用其他基类Box的子类。
 
 ```swift
 struct MyAnyPublisher<Output, Failure: Error> {
     
     let box: PublisherBaseBox< Output, Failure>
     
     init<P>(_ publisher: P) where P: Publisher, P.Output == Output, P.Failure == Failure{
         box = PublisherBox(publisher)
     }
 }
 ```
 
 然后在Publisher协议的`receive`方法中将要包装的Publisher交给我们的box，从上面PublisherBox的实现我们知道，box的receive方法其实是调用被包装的Publisher的`receive`方法，这样一来就达到了包装、转发的目的。
 
 ```swift

 extension MyAnyPublisher: Publisher {
     
     func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
         self.box.receive(subscriber: subscriber)
     }
 }
 ```
 
 最后我们也可以像系统那样提供一个`myEraseToAnyPublisher`来方便Publisher的转化：
 
 ```swift
 extension Publisher {
     func myEraseToAnyPublisher() -> MyAnyPublisher<Output, Failure> {
         MyAnyPublisher(self)
     }
 }
 ```
 */
struct MyAnyPublisher<Output, Failure: Error> {
    
    let box: PublisherBaseBox< Output, Failure>
    
    init<P>(_ publisher: P) where P: Publisher, P.Output == Output, P.Failure == Failure{
        box = PublisherBox(publisher)
    }
}

extension MyAnyPublisher: Publisher {
    
    // 实现 Publisher 协议的方法
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        self.box.receive(subscriber: subscriber)
    }
}

extension MyAnyPublisher {
    
    class PublisherBaseBox<Output, Failure: Error>: Publisher {
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            // do nothing
        }
    }
    class PublisherBox<Base: Publisher>: PublisherBaseBox<Base.Output, Base.Failure> {
        
        let base: Base
        
        init(_ base: Base){
            self.base = base
        }
        
        override
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input{
            self.base.receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    func myEraseToAnyPublisher() -> MyAnyPublisher<Output, Failure> {
        MyAnyPublisher(self)
    }
}

let myAnyPublisher = [1,2,3].publisher.last().myEraseToAnyPublisher()

_ = myAnyPublisher.sink { (value) in
    print("value \(value)")
}

/*:
 
 ### [AnySubscriber](https://github.com/cx-org/CombineX/blob/master/Sources/CombineX/AnySubscriber.swift)
 
 除了AnyPublisher，`AnySubscriber`也是Combine中一个不透明类型的具体实现，与Publisher一样，我们也可以自定义具体的Subscriber来实现控制数据分发的速度等功能。
 
 `Subject`在Combine中是一个特殊的存在，它既可以是Publisher，也可以是Subscriber，所以AnySubscriber也要有对Subject进行包裹。另外，Subscriber协议最主要的是要实现三个`receive`方法，因此我们还可以基于对这个三个方法的block包装来达到对一个Subscriber的包装。
 
 Combine的`AnySubscriber`也是为我们提供了三种便捷包装接口：包装Subscriber实例、包装Subjec、包装receive方法的三个block回调。
 
 ```swift
 public init<S>(_ s: S) where Input == S.Input, Failure == S.Failure, S : Subscriber

 public init<S>(_ s: S) where Input == S.Output, Failure == S.Failure, S : Subject

 public init(receiveSubscription: ((Subscription) -> Void)? = nil, receiveValue: ((Input) -> Subscribers.Demand)? = nil, receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil)
 ```
 
 这个时候我们在创建`MyAnyPublisher`的时候提到的基于类的不透明类型就派上用场了，与MyAnyPublisher一样，我们也需要创建对应的私有`Box`类来完成方法的转发，所不同的是这里我们需要根据这三种包装类型来创建对应的Box子类。
 
 首先还是创建Box基类，这个基类更多的是作为一个通用接口的作用来创建的，这也是基于类的不透明类型的特点：基类用于提供统一的接口，子类实现具体的功能。
 
 ```swift
 class AnySubscriberBaseBox<Input, Failure: Error>: Subscriber {
     
     init() {}
 
     // 这三个方法空实现，交给子类重写
     func receive(subscription: Subscription) {...}
     func receive(_ input: Input) -> Subscribers.Demand {...}
     func receive(completion: Subscribers.Completion<Failure>) {...}
 }
 ```
 
 然后根据不同的包装内容依次创建对应的Box子类，首先创建对Subscriber的Box子类：`AnySubscriberBox`。这个类和上面的`PublisherBox`一样用来持有被包装的Subscriber实例，然后在对应的receive方法中将数据转发给Subscriber实例对象。
 
 ```swift

 final class AnySubscriberBox<Base: Subscriber>: AnySubscriberBaseBox<Base.Input, Base.Failure> {
     
     let base: Base
     
     init(_ base: Base) {
         self.base = base
     }
     
     override func receive(subscription: Subscription) {
         base.receive(subscription: subscription)
     }
     
     override func receive(_ input: Base.Input) -> Subscribers.Demand {
         return base.receive(input)
     }
     
     override func receive(completion: Subscribers.Completion<Failure>) {
         base.receive(completion: completion)
     }
 }
 ```
 
 基于三个block回调的Box子类`AnySubscriberClosureBasedBox`和上面的`AnySubscriberBox`类似，只不过是初始化的时候存储的是block，并且三个`receive`回调中是执行block，将方法的参数进行传递。
 
 ```swift
 final class AnySubscriberClosureBasedBox<Input, Failure: Error>: AnySubscriberBaseBox<Input, Failure> {
     
     // 存储三个block方法
     let receiveSubscriptionThunk: (Subscription) -> Void
     let receiveValueThunk: (Input) -> Subscribers.Demand
     let receiveCompletionThunk: (Subscribers.Completion<Failure>) -> Void
     
     init(
         _ rcvSubscription: @escaping (Subscription) -> Void,
         _ rcvValue: @escaping (Input) -> Subscribers.Demand,
         _ rcvCompletion: @escaping (Subscribers.Completion<Failure>) -> Void
     ) {
         receiveSubscriptionThunk = rcvSubscription
         receiveValueThunk = rcvValue
         receiveCompletionThunk = rcvCompletion
     }
     
     override func receive(subscription: Subscription) {
         receiveSubscriptionThunk(subscription)
     }
     
     override func receive(_ input: Input) -> Subscribers.Demand {
         return receiveValueThunk(input)
     }
     
     override func receive(completion: Subscribers.Completion<Failure>) {
         receiveCompletionThunk(completion)
     }
 }
 ```
 
 最后一个基于Subject的Box子类有些复杂，我们知道Subject是具有双面性的，除了可以接受数据还可以分发数据，所以需要对要包装的Subject加锁以保证安全。
 
 以下代码没有精简，是SubjectSubscriberBox的完整实现，在分析其中实现逻辑之前我们先分下用`RelayState`表示的状态，一共有三种状态：初始、收到Subscription、完成，分别用来对应一个Subscriber接收
 
 ```swift
 enum RelayState {
     case waiting
     case relaying(Subscription)
     case completed
     
    mutating func relay(_ subscription: Subscription) -> Bool {
         guard self.isWaiting else { return false }
         self = .relaying(subscription)
         return true
     }
     
     mutating func complete() -> Subscription? {
         defer {
             self = .completed
         }
         return self.subscription
     }
 }

 ```
 
 ```swift
 final class SubjectSubscriberBox<S: Subject>: AnySubscriberBase<S.Output, S.Failure> {
     
     let lock = Lock()
     var subject: S?
     var state: RelayState = .waiting
     
     init(_ s: S) {
         self.subject = s
     }
     
     deinit {
         lock.cleanupLock()
     }
     
     override func receive(subscription: Subscription) {
         self.lock.lock()
         guard self.state.relay(subscription) else {
             self.lock.unlock()
             subscription.cancel()
             return
         }
         let subject = self.subject
         self.lock.unlock()
         
         subject?.send(subscription: subscription)
     }
     
     override func receive(_ input: Input) -> Subscribers.Demand {
         self.lock.lock()
         switch self.state {
         case .waiting:
             self.lock.unlock()
             APIViolation.valueBeforeSubscription()
         case .relaying:
             let subject = self.subject!
             self.lock.unlock()
             subject.send(input)
             return .none
         case .completed:
             self.lock.unlock()
             return .none
         }
     }
     
     override func receive(completion: Subscribers.Completion<Failure>) {
         self.lock.lock()
         switch self.state {
         case .waiting:
             self.lock.unlock()
         case .relaying:
             self.state = .completed
             let subject = self.subject!
             self.lock.unlock()
             subject.send(completion: completion)
         case .completed:
             self.lock.unlock()
         }
     }
     
     func cancel() {
         guard let subscription = self.lock.withLockGet(self.state.complete()) else {
             return
         }
         subscription.cancel()
         self.subject = nil
     }
 }
 
 ```
 
 */

/*:
 * [Swift Combine 入门导读](https://www.icodesign.me/posts/swift-combine/)
 * [OpaueTypes](https://docs.swift.org/swift-book/LanguageGuide/OpaqueTypes.html)
 * [swiftGG-OpaueTypes](https://swiftgg.gitbook.io/swift/swift-jiao-cheng/23_opaque_types)
 * [swift的类型擦除](https://mp.weixin.qq.com/s/VyUaHcJI7ZYzmVCLhtcRuA)
 */

//: [Next](@next)
