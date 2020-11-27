//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"
/*:
 
 ## 引子
 
 前面我们学习了解了Backpressure，以及软件开发中是如何应对的，同时列举了一些Combine中相关的操作符，那么其内部是如何实现这样一套缓冲机制的呢？
 
 设置缓冲就需要一个集合来保存要缓存的数据，并且对缓存数据的增减操作要保证线程安全，Publisher会对增加缓存数据，缓冲需要对数据有一套完善的计数逻辑，这样可以很平滑的将数据交给Subscriber，
 
 */

private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {

    if let newDemand = newDemand {
//        demandState.requested += newDemand
    }
    
    // If buffer isn't ready for flushing, return immediately
    guard newDemand == Subscribers.Demand.none else { return .none }
    
    return .max(100)
}

let a = flush()

//: [Next](@next)
