//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

/*:
 我们知道`Subject`在Combine中是一个特殊的存在，它既可以作为`Publisher`进行数据分发，又可以成为一个订阅者，其作为一个双面角色在数据分发链中使用。
 
 作为Publisher是因为它本身是继承至`Publisher协议`的。作为Subscriber是因为，`Publisher协议`拓展了`subscribe()`方法：`subscribe(subject:)`，使得它可以作为订阅者。作为一个协议，其有两个具体的类可以用来实现具体的功能，这就使得这样一个存在在Combine中扮演着Publisher、Subscriber、Operators之上最重要的角色。接下来我们就基于它本身的特性以及两个具体的类进行分析，看下如何实现这个中间角色，同时学习下其在Combine内是如何作为基础角色实现某些操作符的。
 
 here wo go!
 
 在Combine中，Subject可以认为
 

 */

/*:
 
 ## CurrentValueSubject
 
 ## PassthroughSubject
 
 */
/*:
 
 ## ConnectablePublisher
 
 ### connect()
 
 ### autoconnect()

 
 
 */
//: [Next](@next)
