//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

/*:
 
 ## 引子
 
 在了解`Backpressure`之前，先看下Combine中是如何控制分发速率的，或者是分发数量。
 
 在前面接触到的操作符中，`output(at:)`会将指定位置的元素分发给下游订阅者。
 */

let aPublisher = PassthroughSubject<Int, Never>()

aPublisher
    .print()
    .output(at: 3)
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("value \($0)")})
    .store(in: &subscriptions)

aPublisher.send(1)
aPublisher.send(2)
aPublisher.send(3)
aPublisher.send(4)
aPublisher.send(5)

aPublisher.send(completion: .finished)

/*:
 看一下控制台输出：
 
 ```
 receive subscription: (PassthroughSubject)
 request unlimited
 receive value: (1)
 request max: (1) (synchronous)
 receive value: (2)
 request max: (1) (synchronous)
 receive value: (3)
 request max: (1) (synchronous)
 receive value: (4)
 value 4
 receive cancel
 completion finished
 ```
 
 会发现，不同于其他操作符的`.print()`输出，这里多了类似于`request max: (1) (synchronous)`这样的语句，这些语句是什么操作引起的呢？
 
 ## Publisher和Subscriber之间是如何产生联系的
 
 在前面`Basic`部分，有通过自定义的`IntSubscriber`来控制数据的分发数量，其中梳理了Publisher和Subscriber之间是如何产生联系的，下面再来回顾下：
 
 >通过Publisher调用`subscribe(_:)`和Subscriber进行绑定，然后Publisher内部会调用Subscriber的`1️⃣receive(subscription:)`方法，传递一个`Subscription实例`，Subscriber可以使用这个Subscription实例，以决定Subscriber接收数据的次数限制。
 >
 > 当用户产生了数据，Publisher会调用Subscriber的`2️⃣receive(_:)`方法，需要注意的是，该方法有可能是`异步调用`，然后根据该方法的返回值决定是否要产生一个新的Publisher。一旦Publisher停止发布（发送一个Completion数据），就会调用Subscriber的`3️⃣receive(completion:)`方法，参数是一个`Completion`枚举，有可能是`完成`，也有可能有一个`错误`。
 
 ![p-2-s](https://assets.alexandria.raywenderlich.com/books/comb/images/9f8c264464ac8f521e79ca6b467112bf760c8252e4f01777f9f5aff7ec4087d9/original.png)
 
 上面的解释中，依次涉及到了`Subscriber协议`中的三个方法。
 
 通过Publisher调用`subscribe`绑定Subscriber的时候，方法1️⃣会被调用，这个时候系统默认调用的应该是`subscription.request(.unlimited)`，所以上面会输出`request unlimited`。如果自定义的Subscriber需要限制接收数据的次数，可以返回对应的`Subscribers.Demand`。需要注意的是，如果返回了`.unlimited`，要有针对大量数据的处理策略，因为这很有可能会导致性能问题发生，也就是本章所说的`Backpressure`。
 
 然后通过aPublisher.send(1)，方法2️⃣会被调用，所以输出了`receive value: (1)`，但是紧接着又输出了`request max: (1) (synchronous)`，从其内容可以看出来是同步执行了`subscription.request(.max(1))`。方法1️⃣用于决定可以为Subscriber分发多少次数据，而在方法2️⃣中，如果有特殊需求，可以根据收到的数据更改这个限制，只需要返回对应的`Subscribers.Demand`即可，需要注意的是，返回的如果是`.max(someNumber)`，其意思是会在原有次数限制上增加该someNumber次的限制，返回`.none`或者`.unlimited`都表示没有次数限制。
 
 通过以上两个方法，可以完成动态的、定量的数据的分发。
 
 但是一个问题是，如果方法1️⃣中发送了`.unlimited`，而在方法2️⃣中返回`.max(whateverNumbe)`都不会生效，不知道系统是怎么办到的。

 */


/*:
 
 ## zip
 
 再以`zip(_:)`操作符为例，它会将两（或三）个publisher分发的数据进行一一对应的组合，然后以元组的形式分发给下游游订阅者。
 
 一个问题是如果其中一个publisher分发的速度很快而其他的很慢，极端一点的情况是一个一直分发数据，但是其他的并不会分发数据，这会有什么影响呢？
 
 我们先可以大致的猜测一下zip内部的实现，他内部会缓存发送较快的publisher的数据，可以将这些数据称为`buffer`，用于和分发较慢的publisher的数据进行组合。数据从Publisher经过Operator处理，到Subscriber接收这个过程可以形象的比喻为管道，Operator为阀门，经过zip这个阀门的数据被逐渐堆积起来，并不会在管道中向下传递数据。
 
 这样在zip这里就会差生很大的压强，来自上游的压力随着数据的增多而变大，这就是`Backpressure`。
 */

let cPublisher = PassthroughSubject<Int, Never>()
let dPublisher = PassthroughSubject<String, Never>()

cPublisher
    .zip(dPublisher)
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("value \($0)")})
    .store(in: &subscriptions)

cPublisher.send(1)
cPublisher.send(2)

dPublisher.send("three")
dPublisher.send("four")

/*:
 
 */

/*:
 ## 如何应对Backpressure
 
 产生`Backpressure`的情况总的来说是由于生产速率远远大于消费速率，针对这样的问题，可以适当、适时的丢弃生产的数据，主要的手段有`节流`、`打包`两种。

 ### 节流
 
 在响应式框架中，有一些常用的手段来解决这个问题：`sample()`、`throttleLast()`、`throttleFirst()`、 `throttleWithTimeout()`、`debounce()`。这些属于使用`节流`的措施来解决问题，从他们的名称中可以猜出来他们具体是何种的策略。
 
 > 从`ReactiveX`的wiki中可以找到这些操作符，不同库的实现有可能会有所不同，但是主要方式还是没什么差异的，这里先以`ReactiveX`组织下的文章来解释。
 
 `sample()或者throttleLast()`的作用是一样的，用于在一定时间间隔内，选取最后一个收到的数据进行分发，而该时间段中其他的数据将会被丢弃。虽然两者的作用是一样的，但是个人认为，叫做sample的意思应该就是在一定时间间隔内的任意一个数据，而不是最后一个数据。
 
 ![sample()](https://github.com/ReactiveX/RxJava/wiki/images/rx-operators/bp.sample.v3.png)
 
 `throttleFirst()`和前两者相反，是选取一定时间间隔内的第一个数据进行分发。
 
 ![throttleFirst()](https://github.com/ReactiveX/RxJava/wiki/images/rx-operators/bp.throttleFirst.v3.png)
 
 `debounce()`和`throttleWithTimeout()`一样，用于在数据分发之后的指定时间间隔内，不继续分发数据给下游订阅者，直到间隔期结束，即使这个期间有收到数据也不进行分发。比如会有需求限制搜索输入框在1秒内不能输入来缓解服务器压力。
 
 ![debounce()](https://github.com/ReactiveX/RxJava/wiki/images/rx-operators/bp.debounce.v3.png)
 
 以上这些节流操作在Combine中被分成了两个：`throttle(for:,scheduler:,latest:)`和`debounce(for:,scheduler:)`。
 
 ### 打包
 
 在前面的学习中使用到的`collect()`操作符就是其中一种`打包`策略，该操作符用于将从上游分发的数据以成组（元组）的形式向下游订阅者分发，以减少数据量的来解决`Backpressure`。
 
 还有其他的打包操作符：`buffer(size:,prefetch:,whenFull:)`，是一种控制性更强的打包策略，并且区分于`collect()`的是，`buffer`是以时间作为主要维度来打包的，而`collect`是以数量为维度打包的。
 
 还有一种打包策略：`window`，可以称其为`滑窗`，设定窗口的大小，跟随着数据的增加来移动窗口，窗口内所能承载的数据达到最多之后就分发给下游，这就是`window`，不过在Combine中并没有这种操作符，看起来其和`collect`很类似，并且`collect()`还有其对应的变种操作符：`collect(strategy:)`可以提供与window相同的效果。

 ### 其他
 
 其实还有其他方案解决`Backpressure`，既然消费者来不及消化生产者提供的数据，那么就等到消费者消化完能力范围内的数据，再接着消化其他数据，也就是`阻塞（block）`。
 
 这种阻塞并不符合响应式的架构，并且在用户端来看并不是一个很好的用户体验：界面卡顿、网页反应慢、视频界面音画不同步等等。抛开这些，如果是在同一个可以阻塞的线程中，这将是一个效率很高的策略。
 */

/*:
 
 ## Reactive pull
 
 在[wiki的这个小节](https://github.com/ReactiveX/RxJava/wiki/Backpressure#how-a-subscriber-establishes-reactive-pull-backpressure)可以看到Combine中关于`Subscribers.Demand`的影子，从该例子中可以看出来Combine应该是借鉴了`Reactive pull`思想。
 
 ``` java
 someObservable.subscribe(new Subscriber<T>() {
     @Override
     public void onStart() {
       request(1);
     }

     @Override
     public void onCompleted() {
       // gracefully handle sequence-complete
     }

     @Override
     public void onError(Throwable e) {
       // gracefully handle error
     }

     @Override
     public void onNext(T n) {
       // do something with the emitted item "n"
       // request another item:
       request(1);
     }
 });
 ```
 还是上面`zip`的例子，如果要组合处理的两个Pubisher为：a和b，a分发的速率比b快很多，这时候由于要缓存a分发的数据会导致buffer越来越大，通过上面我们知道了一些解决方案。使用`throttle`可能并不合适，它会丢弃一些数据，使得数据不完整。其实要做的应该是告诉a，你需要放慢数据分发的速度，应该使用一种减缓`Backpressure`的方案来分发数据，对应的就是上面的`方法2️⃣`，以及上面RxJava实例的`onNext`方法。
 
 这就是`Reactive pull`思想。从消费者（Subscriber）的角度为生产者（Publisher）创建一个主动的pull，相当于回调给生产者，这和以往的被动从生产者接收数据形成了鲜明的对比。
 
 至于Combine是如何实现这种逻辑的，我们会在接下来的章节中探讨。
 */

/*:
 
 相关链接：
 
 * [RxJava-Backpressure](https://github.com/ReactiveX/RxJava/wiki/Backpressure)
 * [Backpressure & Flow Control](https://www.cnblogs.com/ShouWangYiXin/p/10326642.html)
 * [如何形象的描述反应式编程中的背压(Backpressure)机制？--扔物线的回答](https://www.zhihu.com/question/49618581/answer/237078934)
*/

//: [Next](@next)
