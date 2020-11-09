
Combine内置的Publisher有Just, Future, Deferred, Empty, Fail, Record, Published以及PassthroughSubject和CurrentValueSubject。

RxSwift和Combine之间的区别

https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet

## Publishers

Publishers命名空间下的操作符

As an added bonus, operators always have input and output, commonly referred to as upstream and downstream — this allows them to avoid shared state (one of the core issues we discussed earlier).

Combine中的各种operators是定义在Publisher的各种Extension中。在各自的扩展中实现了内置的classes或者structures。举例来说，map(:)操作符返回的对象是Publishers.Map对象。Apple目前内置了50多种Operators。

### 便捷生成Publisher（Convenience Publishers）

#### Sequence

> A publisher that publishes a given sequence of elements.

When the publisher exhausts the elements in the sequence, the next request causes the publisher to finish.

struct Sequence<Elements, Failure>

将队列中的元素进行广播


#### Catch

> A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.

struct Catch<Upstream, NewPublisher>


### 订阅相关（Working with Subscribers）


#### ReceiveOn

> A publisher that delivers elements to its downstream subscriber on a specific scheduler.

struct ReceiveOn<Upstream, Context> 


#### SubscribeOn

> A publisher that receives elements from an upstream publisher on a specific scheduler.

struct SubscribeOn<Upstream, Context>

Context在这里必须是一个Scheduler

### 映射元素（Mapping Elements）

#### TryScan

struct TryScan<Upstream, Output>


#### TryMap

> A publisher that transforms all elements from the upstream publisher with a provided error-throwing closure.

struct TryMap<Upstream, Output> 

#### FlatMap

struct FlatMap<NewPublisher, Upstream>

#### Map

> A publisher that transforms all elements from the upstream publisher with a provided closure.

struct Map<Upstream, Output> 

#### MapError

> A publisher that converts any failure from the upstream publisher into a new error.

struct MapError<Upstream, Failure>

#### Scan

struct Scan<Upstream, Output>

### 过滤元素（Filtering Elements）

#### CompactMap

> A publisher that republishes all non-nil results of calling a closure with each received element.


#### Filter

> A publisher that republishes all elements that match a provided closure.

#### RemoveDuplicates

> A publisher that publishes only elements that don’t match the previous element.

#### ReplaceEmpty

>A publisher that replaces an empty stream with a provided element.

在广播的数据为空的时候替换为一个新的自定义的值

#### ReplaceError

> A publisher that replaces any errors in the stream with a provided element.


#### TryCompactMap

> A publisher that republishes all non-nil results of calling an error-throwing closure with each received element.

#### TryFilter

> A publisher that republishes all elements that match a provided error-throwing closure.

#### TryRemoveDuplicates

> A publisher that publishes only elements that don’t match the previous element, as evaluated by a provided error-throwing closure.

### 分解元素（Reducing Elements）

> reduce:
> vt. 减少；降低；使处于；把…分解
> vi. 减少；缩小；归纳为

#### Collect

> A publisher that buffers items.

#### CollectByCount

> A publisher that buffers a maximum number of items.


#### CollectByTime

> A publisher that buffers and periodically publishes its items.


#### TimeGroupingStrategy

> A strategy for collecting received elements.

#### IgnoreOutput

> A publisher that ignores all upstream elements, but passes along a completion state (finish or failed).

#### Reduce

> A publisher that applies a closure to all received elements and produces an accumulated value when the upstream publisher finishes.


#### TryReduce

> A publisher that applies an error-throwing closure to all received elements and produces an accumulated value when the upstream publisher finishes.


### 对元素应用数学运算（Applying Mathematical Operations on Elements）

#### Comparison

> A publisher that republishes items from another publisher only if each new item is in increasing order from the previously-published item.

只有当每个新项与先前发布的项按`递增顺序`排列时，才会将该数据进行分发。

#### TryComparison

> A publisher that republishes items from another publisher only if each new item is in increasing order from the previously-published item, and fails if the ordering logic throws an error.

#### Count

> A publisher that publishes the number of elements received from the upstream publisher.

仅仅分发从上游收到的指定个数的数据给到下游Publisher。


### 对应元素的Math标准（Applying Mathing Criteria to Elements）

#### AllSatisfy

> Satisfy:
> vt. 满足；说服，使相信；使满意，使高兴
> vi. 令人满意；令人满足

> A publisher that publishes a single Boolean value that indicates whether all received elements pass a given predicate.


#### TryAllSatisfy

> A publisher that publishes a single Boolean value that indicates whether all received elements pass a given error-throwing predicate.

发布一个布尔值的发布者，该值指示所有接收到的元素是否传递给定的错误抛出谓词。

#### Contains

> A publisher that emits a Boolean value when a specified element is received from its upstream publisher.

#### ContainsWhere

> A publisher that emits a Boolean value upon receiving an element that satisfies the predicate closure.

#### TryContainsWhere

> A publisher that emits a Boolean value upon receiving an element that satisfies the throwing predicate closure.


### 对元素应用序列操作（Applying Sequence Operations to Elements）

#### FirstWhere

> A publisher that only publishes the first element of a stream to satisfy a predicate closure.


#### LastWhere

> A publisher that only publishes the last element of a stream that satisfies a predicate closure, once the stream finishes.

#### DropUntilOutput

> A publisher that ignores elements from the upstream publisher until it receives an element from second publisher.

#### DropWhile

> A publisher that omits elements from an upstream publisher until a given closure returns false.

#### TryDropWhile

> A publisher that omits elements from an upstream publisher until a given error-throwing closure returns false.

#### Concatenate

> A publisher that emits all of one publisher’s elements before those from another publisher.

#### Drop

> A publisher that omits a specified number of elements before republishing later elements.

#### PrefixUntilOutput

#### PrefixWhile

> A publisher that republishes elements while a predicate closure indicates publishing should continue.

#### First

> A publisher that publishes the first element of a stream, then finishes.

#### Last

> A publisher that only publishes the last element of a stream, after the stream finishes.

#### TryFirstWhere

> A publisher that only publishes the first element of a stream to satisfy a throwing predicate closure.

#### TryLastWhere

> A publisher that only publishes the last element of a stream that satisfies a error-throwing predicate closure, once the stream finishes.

#### TryPrefixWhile

> A publisher that republishes elements while an error-throwing predicate closure indicates publishing should continue.

#### Output

> A publisher that publishes elements specified by a range in the sequence of published elements.


### 组合来自多个发布者的元素（Combining Elements from Multiple Publishers）

#### CombineLatest

> A publisher that receives and combines the latest elements from two publishers.

#### CombineLatest3

> A publisher that receives and combines the latest elements from three publishers.

#### CombineLatest4

> A publisher that receives and combines the latest elements from four publishers.

如何自己创建一个`CombineLatest5`呢？？

#### Merge

> A publisher created by applying the merge function to two upstream publishers.

#### Merge3

> A publisher created by applying the merge function to three upstream publishers.

#### MergeMany

根据一个序列来进行Merge操作，打破了Merge的个数限制。

#### Zip

> A publisher created by applying the zip function to two upstream publishers.


### 捕获错误（Handling Errors）

try-catch、断言

#### AssertNoFailure

> A publisher that raises a fatal error upon receiving any failure, and otherwise republishes all received input.

使用此函数进行内部完整性检查，这些检查在测试期间处于活动状态，但不会影响发送代码的性能。

#### Catch

> A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher.

#### TryCatch

> A publisher that handles errors from an upstream publisher by replacing the failed publisher with another publisher or producing a new error.

由于此发布者的处理程序可以抛出一个错误，因此发布者。TryCatch将其失败类型定义为Error。这与Publishers.Catch不同，它从替换发布服务器获取其故障类型。

#### Retry

> A publisher that attempts to recreate its subscription to a failed upstream publisher.

### 时间维度（Controlling Timing）

#### Debounce

> A publisher that publishes elements only after a specified time interval elapses between events.

去抖动，类似于`延时`操作，防止在短时间内重复操作

#### Delay

> A publisher that delays delivery of elements and completion to the downstream receiver.

#### MeasureInterval

> A publisher that measures and emits the time interval between events received from an upstream publisher.

测量时间间隔，

#### Throttle

> A publisher that publishes either the most-recent or first element published by the upstream publisher in a specified time interval.

阈值

#### Timeout

Terminates publishing if the upstream publisher exceeds the specified time interval without producing an element.

### 扁平（Adapting Publishers Types）

#### SwitchToLatest

> A publisher that “flattens” nested publishers.

Given a publisher that publishes Publishers, the SwitchToLatest publisher produces a sequence of events from only the most recent one. For example, given the type Publisher<Publisher<Data, NSError>, Never>, calling switchToLatest() will result in the type Publisher<Data, NSError>. The downstream subscriber sees a continuous stream of values even though they may be coming from different upstream publishers.

### 引用类型的Publisher（Creating Reference-type Publishers）

#### Share

> A publisher implemented as a class, which otherwise behaves like its upstream publisher.


### 编解码（Encoding and Decoding）

#### Decode


#### Encode


### 使用KayPaths做属性标识（Identifying Properties with Key Paths）

#### MapKeyPath

> A publisher that publishes the value of a key path.

#### MapKeyPath2

> A publisher that publishes the values of two key paths as a tuple.

#### MapKeyPath3

> A publisher that publishes the values of three key paths as a tuple.

### 使用显式发布服务器连接（Using Explicit Publisher Connections）

#### Autoconnect

> A publisher that automatically connects and disconnects from this connectable publisher.

自动与此可连接发布服务器连接或断开连接的发布服务器。

### 多个订阅（Working with Multiple Subscribers）

#### Multicast

> A publisher that uses a subject to deliver elements to multiple subscribers.

当您有多个下游订阅者，但希望上游发布者每个事件只处理一个receive(_:)调用时，请使用多播发布者。


### 缓冲元素（Buffering Elements）

#### Buffer

> A publisher that buffers elements from an upstream publisher.

#### BufferingStrategy

> A strategy for handling exhaustion of a buffer’s capacity.

一种处理缓冲区容量耗尽的策略。

#### PrefetchStrategy

> A strategy for filling a buffer.

### 显示添加可连接性（Adding Explicit Connectability）

#### MakeConnectable

> A publisher that provides explicit connectability to another publisher.

Call connect() on this publisher when you want to attach to its upstream publisher.


### 可调式（Debugging）

#### Breakpoint

> A publisher that raises a debugger signal when a provided closure needs to stop the process in the debugger.

When any of the provided closures returns true, this publisher raises the SIGTRAP signal to stop the process in the debugger. Otherwise, this publisher passes through values and completions as-is.

当提供的任何闭包返回true时，该发布程序将在调试器中发出SIGTRAP信号以停止进程。否则，该发布程序将按原样传递值和完成。

#### HandleEvents

> A publisher that performs the specified closures when publisher events occur.

#### Print

> A publisher that prints log messages for all publishing events, optionally prefixed with a given string.


### Map系列的操作符

### Try系列的操作符


