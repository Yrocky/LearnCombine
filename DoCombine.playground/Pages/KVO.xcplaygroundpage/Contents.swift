//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"
var subscriptions = Set<AnyCancellable>()

example(of: "publisher(for:)") {
    
    /*:
     在前面我们使用`assign(to:on)`来完成数据和模型的绑定，
     但如果要监听一个对象的属性变化，可以使用KVO，Combine也提供了相应的操作符。
     `publisher(for:)`就是这样的一个
     */
    
    let queue = OperationQueue()
    
    queue.publisher(for: \.operationCount)
        .sink {
            print("value \($0)")
        }
    queue.addOperation {
        print("operation 1")
    }
    queue.addOperation {
        print("operation - 2")
    }
    
    /*:
     如果你要使用KVO相关的操作符，你必须使用class，并且是继承至NSObject的，同时需要观察的属性需要使用`@objc dynamic`来标记
     */
    
    class Animal: NSObject {
        class Object: NSObject {
            var stringProperty = "default string"
            @objc dynamic var integerProperty = 0
        }
        
        @objc dynamic var legs : Int = 10
        @objc dynamic var color : String
        @objc dynamic var arrayProperty: [Float]
        @objc dynamic var obj = Object()
        
        init(_ color: String) {
            self.color = color
            arrayProperty = []
        }
    }
    
    let cow = Animal("red")
    
    /*:
     虽然是在初始化之后添加的publisher，
     但还是将属性初始化的时候的改动也分发了出去，
     比如下面会输出：10、3、4
     */
    cow.publisher(for: \.legs)
        .sink {
            print("current value: \($0)")
        }
    cow.legs = 3
    cow.legs = 4
    
    /*:
     对应的打印为：red、green
     */
    cow.publisher(for: \.color)
        .sink {
            print("current color: \($0)")
        }
    cow.color = "green"
    
    /*:
     使用数组的属性也是一样的，所不同的是每次修改数组的内容就会触发KVO
     */
    cow.publisher(for: \.arrayProperty)
        .sink {
            print("current array:\($0)")
        }
    cow.arrayProperty.append(10.0)
    cow.arrayProperty.append(20.0)
    cow.arrayProperty.remove(at: 1)
    
    /*:
     我们使用一个自定义的class来作为属性，看下修改它、修改它的属性是否会触发KVO。
     */
    cow.publisher(for: \.obj)
        .sink {
            print("current obj:\($0)")
        }
    cow.obj.stringProperty = "new string"
    /*:
     通过以上的实验我们看到，修改obj的属性并不会触发KVO，
     下面我们基于KVO的链式操作来观察obj的属性，看下会如何，
     需要注意的是，obj的stringProperty属性目前是没有使用`@objc dynamic`修饰的。
     */
//    cow.publisher(for: \.obj.stringProperty)
//        .sink {
//            print("current obj.string:\($0)")
//        }
//    cow.obj.stringProperty = "new string2"
    
    /*:
     这个时候我们发现控制台输出了错误：`Fatal error: Could not extract a String from KeyPath Swift.ReferenceWritableKeyPath`，大致意识就是这个Stirng的属性并不可用于Combine-KVO。
     
     下面我们为obj的属性添加上`@objc dynamic`来修饰。
     */
    cow.publisher(for: \.obj.integerProperty)
        .sink {
            print("current obj.int:\($0)")
        }
    cow.obj.integerProperty = 1
    cow.obj.integerProperty = 2
    /*:
     会发现，可以成功的将KVO的数据进行分发。
     
     总结如下，如果想要自定义的数据类型支持Combine-KVO，
     * 需要使用继承至`NSObject`的class
     * 要观察的属性可以是系统内置的String、Int、Float、Array、Dictionary等等
     * 如果要观察自定义属性的属性，需要自定义属性也遵守前面2步的规则
     */
    
    class Person: ObservableObject {
        @Published var name = ""
    }
    
    let rocky = Person()
    //: 编译报错
    //rocky.publisher(for: \.legs)
}

example(of: "pure swift in @objc") {
    
    /*:
     我们可以完成以上的操作，全靠swift与OC之间的桥接，
     而如果使用一个纯swift的类型来进行观察，很显然是不行的，
     比如使用结构体来作为属性的时候就编译不通过，
     提示：`Property cannot be marked @objc because its type cannot be represented in Objective-C`
     */
    
    struct MyStruct {
        let a: (Int, Bool)
    }
    class MyObject: NSObject{
//        @objc dynamic var structProperty: MyStruct = .init(a: (12,false))
    }
}

example(of: "options") {

    /*:
     KVO在用来观察值变化的时候还为我们提供了更便捷的操作：新值、旧值，
     而到了Combine-KVO中，这样的选择就更多了，`publisher(for:)`还有一个变形方法：`publisher(for:options:)`
     */
    
    class MyObject: NSObject{
        @objc dynamic var stringProperty = ""
        @objc dynamic var integerProperty = 0
    }
    
    let obj = MyObject()
    /*:
     在前面使用`publisher(for:)`的时候会分发出来属性的初始值，
     有时候这个值我们并不关心，我们只关心旧值到新值的变化，
     这个时候就可以使用`options`来完成对应的操作。
     
     可选的类型有：
     * initial 初始值
     * new 新值
     * old 旧值
     * prior 新值和旧值
     */
    obj.publisher(for: \.stringProperty, options: [.new])
        .sink {
            print("new:\($0)")
        }
    
    obj.stringProperty = "aa"
    
    /*:
     我们发现，只要值有变化，就会分发两个数据，分别是老数据和新数据，
     并不是以元组的方式进行分发，这点并不是特别的好
     */
    obj.publisher(for: \.integerProperty, options: [.prior])
        .sink {
            print("prior:\($0)")
        }
    
    obj.integerProperty = 1
    obj.integerProperty = 2
    obj.integerProperty = 3
}

example(of: "ObservalbeObject") {
    /*:
     上面所涉及到的`publisher(for:)`主要用来对OC类型的数据进行Combine的拓展，
     而对于swift类型的数据就不必这么麻烦了，Combine提供了`ObservalbeObject`协议，
     该协议可以让swift的class（仅限于class，struct、enum等则不行）具备可以分发数据的功能。
     
     他的定义如下：
     ```swift
     public protocol ObservableObject : AnyObject {

         /// The type of publisher that emits before the object has changed.
         associatedtype ObjectWillChangePublisher : Publisher = ObservableObjectPublisher where Self.ObjectWillChangePublisher.Failure == Never

         /// A publisher that emits before the object has changed.
         var objectWillChange: Self.ObjectWillChangePublisher { get }
     }
     ```
     
     
     */
    
    class MyClass: ObservableObject {
        @Published var stringProperty = ""
        @Published var integerProperty = 1
    }
    
    let obj = MyClass()
    
    obj.objectWillChange
        .sink {
            print("value:\($0)")
    }
    
    obj.stringProperty = "new string"
    obj.integerProperty = 2
    /*:
     我们发现，在`sink`中并没有办法获取到关于obj的任何属性数据，
     这是因为`ObservableObjectPublisher`这个Publisher的Output为`Void`，
     并且`objectWillChange`这个属性也仅仅是用于通知外部，obj有属性将要有所变动。
     
     结合同时期发布的swiftUI，这个特性还是很有用的，可以用来在任意一个属性有变动的时候更新ui。
     */
}
//: [Next](@next)
