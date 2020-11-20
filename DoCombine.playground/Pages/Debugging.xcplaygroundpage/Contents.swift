//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

/*:
 
 ## print()
 
 在之前的很多实例中我们会使用`.print(_:,to:)`操作符来进行一些日志输出，
 控制台输出Combine框架在关键节点的日志信息，
 从另一个方面来说，使得我们对Combine的逻辑流程更加清晰。
 */

let aPublisher = CurrentValueSubject<Int, Never>(2)

_ = aPublisher
    //: 为`.print(_:,to:)`增加第一个参数，可以作为标识，一般用来标识是哪个Publisher
    .print("aPublisher")
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("value \($0)")})

aPublisher.send(3)

/*:
 `.print(_:,to:)`的第二个参数接收的是一个`TextOutputStream?`类型，
 这个实例需要遵守`TextOutputStream`协议，
 它是Swift基础库中的一部分，通过该协议可以自定义输出文本的格式。
 
 其只有一个方法`func write(String)`，用于将传入的String进行自定义转化，
 可以在对应的log中加入当前的日期、方法调用的时长、log类型等等。
 
 下面先创建一个遵守`TextOutputStream`协议的结构体。
 */

struct MyLogger: TextOutputStream {
    
    func write(_ string: String) {

        //: 有可能会有空的输出，对其进行丢弃
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("MyLogger \(string)")
    }
}

let bPublisher = CurrentValueSubject<Int, Never>(20)

_ = bPublisher
    .print("bPublisher", to: MyLogger())
    .sink{ _ in }

bPublisher.send(40)

/*:
 使用了`MyLogger()`之后，控制台对应的输出为：
 
 ```
 MyLogger bPublisher: receive subscription: (CurrentValueSubject)
 MyLogger bPublisher: request unlimited
 MyLogger bPublisher: receive value: (20)
 MyLogger bPublisher: receive value: (40)
 MyLogger bPublisher: receive cancel
 ```
 */

/*:
 ## handleEvents
 
 除了`print()`之外，Combine还提供了更加详细节点的事件捕获：`handleEvents`，
 在各个时期为开发者提供了钩子，使得debug的粒度更加精细。
 
 */

let subscription = URLSession.shared
    .dataTaskPublisher(for: URL(string: "https:www.baidu.com")!)
    .handleEvents(receiveSubscription: { _ in
        print("receive subscription")
    }, receiveOutput: { (data, response) in
        print("receive output")
    }, receiveCompletion: { (completion) in
        print("receive completion")
    }, receiveCancel: {
        print("receive cancel")
    }, receiveRequest: { (demand) in
        print("receive request")
    })
    .sink(receiveCompletion: { (compleiton) in
        print("completion")
    }) { data, response in
        print("data \(data.count)")
}

/*:
 
 ## brinkpoint
 
 最后一个操作符是`brinkpoint`，该操作符允许提供一个返回值为Bool类型的block，来决定是要要发出一个`SIGTRAP`信号，从而在调试器中停止进程。
 
 需要注意的是，这个操作符应该用于处理很特殊的情形，作为实在没有办法的一种debug手段。
 */

let dPublisher = PassthroughSubject<Int, Never>()

_ = dPublisher
    .breakpoint(receiveOutput: { (value) -> Bool in
        return value == 30
    })
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("value \($0)")})

dPublisher.send(10)
dPublisher.send(30)
dPublisher.send(20)

//: [Next](@next)
