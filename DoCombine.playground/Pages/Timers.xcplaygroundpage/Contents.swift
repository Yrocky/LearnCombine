//: [Previous](@previous)

import Foundation
import Combine
import Dispatch

var str = "Hello, playground"

/*:
 
 ## RunLoop
 
 我们知道任何一个线程都有一个自己的`RunLoop`，
 
 */

let runLoop = RunLoop.main

_ = runLoop.schedule(
    after: runLoop.now,
    interval: .seconds(1),
    tolerance: .milliseconds(100)) {
    print("fire")
}

/*:

## Timer

*/

let a = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()
//    .scan(0) { counter, _ in counter + 1 }
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("value \($0)")})

//let subscription = Timer
//    .publish(every: 1.0, on: .main, in: .common)
//    .autoconnect()
//    .scan(0) { counter, _ in counter + 1 }
//    .sink { counter in
//        print("Counter is \(counter)")
//}

/*:
 
 ## DispatchTimerSource
 
 还可以使用分派队列来生成计时器事件。
 
 虽然`Dispatch `有一个`DispatchTimerSource事件源`，但令人惊讶的是，Combine没有为它提供计时器接口。相反，您将使用另一种方法在队列中生成计时器事件。
 
 */

let queue = DispatchQueue.main

let source = PassthroughSubject<Int, Never>()

var counter = 0

//: 使用`DispatchQueue`开启一个定时器
let cannable = queue.schedule(after: queue.now, interval: .seconds(1)) {
    print("aaa \(counter)")
    //: 在定时器中让Publisher分发数据，这样就变相的创建了一个定时器Publisher
    source.send(counter)
    counter += 1
}

let subscription = source.sink {
    print("timer value \($0)")
}

//: [Next](@next)
