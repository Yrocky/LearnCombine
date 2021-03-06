//: [Previous](@previous)

import Foundation
import SwiftUI

var str = "Hello, playground"
/*:
 `FunctionBuilder`是在swift5.1新加的特性，主要应用于SwiftUI中，它允许我们在函数的最后一个闭包参数中使用。
 
 我们先来看个例子：VStack:
 
 ```swift
 struct VStack<Content> : View where Content : View {

     @inlinable public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content)
 
     public typealias Body = Never
 }
 ```
 
 其初始化函数中最后的参数就是使用了`@ViewBuilder`来修饰的，这允许我们使用如下的方式来初始化一个VStack。
 */

example(of: "basic") {
    
    _ = VStack{
        Text("hello")
        Text("world")
        Text("!")
    }
}

example(of: "basic - if") {

    let can = false
    
    _ = VStack{
        Text("hello")
        Text("world")
        if can {
            Text("!")
        }
    }
}

example(of: "basic - switch") {

    //: 貌似不可以使用switch-case，会报错，但是编译是可以通过的。
    
    return
    enum Language {
        case swift
        case objc
        case vue
    }
    
    let lang = Language.swift
    
    _ = VStack{
        Text("hello")
        Text("world")
        Text("by")
        switch lang {
        case Language.swift:
            Text("swift")
        case Language.objc:
            Text("objc")
        case Language.vue:
            Text("vue")
        }
    }
}

/*:
 
 其中省略了逗号，return，这也都是5.1之后的新特性，同时在FunctionBuilder内还可以使用简单的if-else、switch-case等判断语句。
 
 */

example(of: "VStack") {
    return
    enum Language {
        case swift
        case objc
        case vue
    }
    
    let sweet = true
    let lang = Language.vue
    
    _ = VStack{
        Text("hello")
        switch lang {
        case Language.swift:
            Text("swift")
        case Language.objc:
            Text("objc")
        case Language.vue:
            Text("vue")
        }
        Text("world")
        if sweet {
            Text("~")
        } else {
            Text("!")
        }
    }
}

//let vb = ViewBuilder()

/*:
 具体的，我们来看下ViewBuilder的定义：
 ```swift
 @_functionBuilder
 struct ViewBuilder {

     public static func buildBlock() -> EmptyView

     public static func buildBlock<Content>(_ content: Content) -> Content where Content : View
 }
 ```
 
 可以看到有一个关键词：`@_functionBuilder`，通过这个标记就可以将对应的结构体作为Function Builder来使用了。同时还看到了两个`buildBlock`静态函数，builder就是通过这两个方法来生成对应内容的。
 
 我们在构建界面的时候使用最多的还是拓展中的`buildBlock`方法，一共有9个，这些方法返回的是`TupleView`，它本身也是View，只不过是根据元组来承载内容的。
 
 ```swift
 extension ViewBuilder {

     public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)> where C0 : View, C1 : View
 }
 ```
 */

example(of: "ViewBuilder & TupleView") {

    //: 下面是我们常规使用VStack的方式
    _ = VStack{
        Text("hello")
        Text("world")
    }
    
    //: 其实根据其返回类型，可以直接这个样子编写，编译器会根据具体数量来使用对应的构造方法
    _ = VStack {
        return ViewBuilder.buildBlock(Text("hello"), Text("world"))
    }
    
    //: 甚至可以直接使用TupleView来使用，结果是一样的
    _ = VStack {
        return TupleView((Text("hello"), Text("world")))
    }
}

//let tupleView = TupleView()

/*:
 下面，我们使用`@_functionBuilder`来实现一个自己的Group。
 */

example(of: "Custom Group") {
    
    /*:
     playground是为Source文件夹下的内容提供了一个特殊的Module，这个Module以`playground文件名+PageSources`命名，
     所以我们要使用自定义的Group、Cell就需要添加对应的模块名：`FunctionBuilder_PageSources`。
     */
    
    let can = false
    
    let group = FunctionBuilder_PageSources.Group {
        FunctionBuilder_PageSources.Cell("a")
//        if can {
//            FunctionBuilder_PageSources.Cell("maybe show")
//        }
        FunctionBuilder_PageSources.Cell("b")
        FunctionBuilder_PageSources.Cell("c")
        FunctionBuilder_PageSources.Cell("d")
    }

    print("can:\(can) group.nodes:\(group.nodes)")
    
}

/*:
 *[awesome-function-builders](https://github.com/carson-katri/awesome-function-builders)
 *[小专栏](https://xiaozhuanlan.com/topic/0652738149)
 */
//: [Next](@next)
