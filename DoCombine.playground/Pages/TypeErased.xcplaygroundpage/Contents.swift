//: [Previous](@previous)

import Foundation

var str = "Hello, playground"
/*:
 `type-erased`是swift中比较常用的一个手段，主要用来实现`类型擦除`的功能，将遵守协议的具体事例进行类型的抹除。
 
 比如这里创建一个`Human`的协议，他有三个方法，然后我们创建一个`AnyHuman`的结构体，用来实现`type-erased`。我们实现的AnyHuman需要有和Human一致的特性，也就是要实现其全部的协议方法，一般来说都是直接让AnyHuman遵守Human协议。
 
 ```swift
 public protocol Human {
     func speak() -> Void
     func run() -> Void
     func see() -> Void
 }
 
 public struct AnyHuman: Human {
     public func speak() { // todo.. }
     public func run() { // todo.. }
     public func see() { // todo.. }
 }
 ```
 
 AnyHuman内部是使用一个`box`来完成多类型的包装，通过这个box将不同类型的实例放到AnyHuman中，它本身是一个黑盒的作用，然后，box内部会根据包装的类型来进行消息的转发。这个box需要和AnyHuman、Human的行为一致。
 
 `HumanBox`就是我们实现的box，定义如下，它会持有具体的遵守Human协议的实例对象，然后在对应的方法被调用的时候，使用这个实例对象的实现，这样一来就完成了抹平类型差异的功能。
 
 ```swift
 
 fileprivate protocol AnyHumanBox: Human {
     var base: Any { get }
 }
 
 fileprivate struct HumanBox<Base: Human>: AnyHumanBox {
     
     private let _base: Base
     
     var base: Any { return _base }
     
     init(_ base: Base) { self._base = base }
     
     func speak() { _base.speak() }
     func run() { _base.run() }
     func see() { _base.see() }
 }
 ```
 
 这个时候修改AnyHuman，使用该box来完成对应的事件转发。
 
 ```swift
 public struct AnyHuman: Human {
     
     fileprivate let box: AnyHumanBox
     
     public var base: Any {
         return self.box.base
     }
     
     public init<Base: Human>(_ base : Base) {
         // 如果是根据一个`AnyHuman`来创建`AnyHuman`，直接使用
         if let anyHuman = base as? AnyHuman {
             self = anyHuman
         } else {
             // 否则就使用box来做中转
             box = HumanBox(base)
         }
     }
 
     public func speak() { box.speak() }
     public func run() { box.run() }
     public func see() { box.see() }
 ```
 */

/*:
 
 下面简单的创建三个类型，他们都遵守`Human`协议，然后使用AnyHuman放入到一个数组中，通过遍历数组，可以正确的完成对应类型的方法调用。
 
 */
struct Chinese: Human {
    
    var name: String
    init(_ name: String) { self.name = name }
    
    func speak() { print("\(name) 说话...") }
    func run() { print("\(name) 跑...") }
    func see() { print("\(name) 看...") }
}

struct British: Human {
    
    var name: String
    init(_ name: String) { self.name = name }
    
    func speak() { print("\(name) speak...") }
    func run() { print("\(name) run...") }
    func see() { print("\(name) see...") }
}

struct Emoji: Human {
    
    var name: String
    init(_ name: String) { self.name = name }
    
    func speak() { print("\(name) 🎤...") }
    func run() { print("\(name) 🏃...") }
    func see() { print("\(name) 👀...") }
}

var array = [AnyHuman]()

array.append(AnyHuman(Chinese("杨恒")))
array.append(AnyHuman(British("rocky")))
array.append(AnyHuman(Emoji("😈")))

// do see
array.forEach { anyHuman in
    anyHuman.see()
//    print(anyHuman)
}

/*:
 
 通过上面的代码可以看到对应的打印为：
 
 ```
 杨恒 看...
 rocky see...
 😈 👀...
 ```
 这符合我们的预期。
 
 */

/*:
 
 以上简单的实现了一个type-erased，可能面对这样的实现会有一些疑问，为什么还需要使用一个box角色来完成转发实现呢？为什么不直接使用AnyHuman来做这件事儿呢？
 
 假如直接使用AnyHuman来完成转发，内部不使用box。我们创建一个新的实例：`AnyHuman_`，它同样和Human具备一样的行为，但是内部并不将行为使用私有的box来转发，而是自己来完成转发，通过初始化的时候存储的`_base`来转发。
 
 ```swift
 
 public struct AnyHuman_: Human {
     
     fileprivate let _base: Human
     
     public var base: Any {
         return self._base
     }
     
     public init<Base: Human>(_ base : Base) {
         if let anyHuman = base as? AnyHuman_ {
             self = anyHuman
         } else {
             self._base = base
         }
     }
 
     public func speak() { _base.speak() }
     public func run() { _base.run() }
     public func see() { _base.see() }
 }
 ```
 */

print("====== ======")

let array_2 = [
    AnyHuman_(Chinese("杨恒")),
    AnyHuman_(British("rocky")),
    AnyHuman_(Emoji("👿"))
]

array_2.forEach {
    print($0.speak())
//    print($0)
}

/*:

 通过控制台的打印我们发现，输出结果并不是我们想要的：
 
 ```
 杨恒 说话...
 ()
 rocky speak...
 ()
 👿 🎤...
 ()
 ```
 每一个输出语句下面都多了一个`()`，这个是什么？很奇怪，怎么会多一对括号呢？
 */

/*:
 下面我们使用`类`来实现类型擦除，通过比较`AnySequence`可以看出来，系统并不是使用这种方式实现的：
 
 ```swift
 print(AnySequence<Any>(other_array))
 // AnySequence<Any>(_box: Swift._SequenceBox<Swift.Array<Any>>)

 print(MyAnySequence_class<Any>.make(some_set))
 // MyAnySequenceImpl_class<Swift.Set<Swift.Int>>

 print(some_array.eraseToMyAnySequence())
 // MyAnySequenceImpl_class<Swift.Array<Swift.Int>>

 ```
 */

let some_set = Set([10,12,30,84,5])
let some_array = [43,7,2,67,79,9]
let other_array = ["a","b","c","d"]

print(AnySequence<Any>(other_array))
// AnySequence<Any>(_box: Swift._SequenceBox<Swift.Array<Any>>)

print(MyAnySequence_class<Any>.make(some_set))
// MyAnySequenceImpl_class<Swift.Set<Swift.Int>>

print(some_array.eraseToMyAnySequence())
// MyAnySequenceImpl_class<Swift.Array<Swift.Int>>

print(Mirror(reflecting: some_array.eraseToMyAnySequence()))
//Mirror for MyAnySequenceImpl_class<Array<Int>>

protocol SomeProtocol {
    associatedtype E
    
    func some() -> E
}

struct AAA: SomeProtocol {
    typealias E = String
    
    func some() -> String {
        "dot dot"
    }
}

struct BBB: SomeProtocol {
    typealias E = Int
    
    func some() -> Int {
        1314
    }
}

/*
 
 * [type-erasure-in-swift](https://www.mikeash.com/pyblog/friday-qa-2017-12-08-type-erasure-in-swift.html)
 * [type-erasure in swiftUI](https://swiftwithmajid.com/2019/12/04/must-have-swiftui-extensions/)
 */
//: [Next](@next)
