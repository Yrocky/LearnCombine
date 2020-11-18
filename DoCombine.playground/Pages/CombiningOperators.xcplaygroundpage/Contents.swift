//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

public func example(of description: String, action: () -> Void) {
    
    print("\n--- Example of:", description, "---")
    action()
}

example(of: "Combining") {
    /*:
     前面通过转换、过滤等操作符，可以完成对已有publisher的相应处理，
     其中也涉及到了多个publisher的操作符：
     `drop(untilOutputFrom:)`、`prefix(untilOutputFrom:)`。
     除了对单一publisher的转化、过滤操作，多publisher的组合操作也是一个很核心的功能。
     */
}

example(of: "prepend(_:)") {
    /*:
     `prepend(_:)`可以在当前publisher之前追加指定内容的元素，
     可以接受`Sequence`，Sequence内可以是和当前publisher同类型的元素，
     也可以是通过`Publishers.Sequence`得到的publisher。
     
     只要是和当前publisher的output同类型的`Sequence`，都可以作为`prepend`的参数，
     下面列举了元组、数组和数字作为参数的实例，
     其实单个数字会被当成元组来对待，所以本质上还是元组和数组。
     集合和数组类似，这里并没有做相关实例。
     */
    
    let tupleSequence = (11,21,31)
    let arraySequence = [11,22,33]
    let singleSeqnence = 55
    
    [1,2,3]
        .publisher
//        .prepend(tupleSequence)
//        .prepend(arraySequence)
        .prepend(singleSeqnence)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    [1,2,3,4]
        .publisher
        .prepend(1,2)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    
    let otherPublisher = (5...6).publisher
    let otherPublisherSequence = [Just(100),Just(200)]
    
    /*:
     上面说了，Sequence中也可以是其他的publisher，
     这个意思是说，必须是`Publishers.Sequence`类型，
     而不是说，是一个装有Publisher的Sequence，比如装有多个publisher实例的数组。
     
     由于`otherPublisher`是一个Publishers.Sequence的实例，所以可以作为参数，其对应的输出日志为：
     
     ```
     value 5
     value 6
     value 1
     value 2
     value 3
     completion finished
     ```
     
     而`otherPublisherSequence`作为一个元素为Publisher的Sequence，并不符合这里的定义，
     但是，它也可以作为prepend的参数，通过输出可以发现，其实只是在前面追加了一个值：
     
     ```
     value [Combine.Just<Swift.Int>(output: 100), Combine.Just<Swift.Int>(output: 200)]
     value 1
     value 2
     value 3
     completion finished
     ```
     
     这里`otherPublisherSequence`内的元素（通过Just得到的pubisher）和当前publisher的数据并不相同，
     但还是可以编译通过，甚至不会报警告。
     */
    [1,2,3]
        .publisher
//        .prepend(otherPublisher)
        .prepend(otherPublisherSequence)// 并不可以
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    [1,2,3]
        .publisher
        // 只要是swift基础库中和publisher同数据类型的Sequence都可以
        .prepend(stride(from: 4, to: 10, by: 2))
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
}

example(of: "prepend(_:) 2") {
    /*:
     用`prepend(_:)`前项追加一个`PassthroughSubject`，
     分别在添加依赖前以及添加依赖后，让otherPublisher分发数据，
     会发现只有添加依赖后的数据会被前项追加，
     同时publisher需要知道otherPublisher何时完成所有数据的分发，
     因此在otherPublisher发送completion之后才会将对应的数据进行追加。
     */
    
    let otherPublisher = PassthroughSubject<Int, Never>()
    otherPublisher.send(100)
    otherPublisher.send(200)
    
    [1,2,3]
        .publisher
        .prepend(otherPublisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    otherPublisher.send(300)
    
    otherPublisher.send(completion: .finished)
}

example(of: "append(_:)") {
    /*:
     和`prepend(_:)`相反，`append(_:)`是在当前publisher发布数据之后追加数据，
     同样的也是支持追加`Publishers.Sequence`，以及含有相同类型元素的Sequence。
     */
    
    [1,2,3,4]
        .publisher
        .append(10,11)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    let publisher = PassthroughSubject<Int, Never>()
    let otherPublisher = (5...6).publisher

    publisher
        .print()
        .append(otherPublisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    publisher.send(1)
    publisher.send(2)
    publisher.send(3)
    
    /*:
     这个时候并不会为publisher追加元素，这很好理解，因为是要在尾部追加元素，
     send(3)之后，并不知道是否已经在尾部了，
     只有在发送了`completion`之后才标志着publisher已经完成了数据的分发，
     这时候为其`append`的Sequence就会被发送出来。
     
     通过打印log可以发现，虽然收到了`finished`消息，
     但并没有立即调用`receiveCompletion`，
     而是先将缓存的otherPublisher中的数据发送出去，再调用`receiveCompletion`。
     
     ```
     request unlimited
     receive value: (1)
     value 1
     receive value: (2)
     value 2
     receive value: (3)
     value 3
     receive finished
     value 5
     value 6
     completion finished
     ```
     */
    publisher.send(completion: .finished)
    
    print("----- test otherPassthroughSubject -----")
    
    let newPublisher = PassthroughSubject<Int, Never>()
    let otherPassthroughSubject = PassthroughSubject<Int ,Never>()

    otherPassthroughSubject.send(400)
    
    newPublisher
        .print()
        .append(otherPassthroughSubject)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    newPublisher.send(11)
    newPublisher.send(21)
    newPublisher.send(31)
    
    otherPassthroughSubject.send(300)
    
    newPublisher.send(completion: .finished)
    /*:
     这里再模拟一个场景，
     如果要追加的publisher是在当前publisher发送了`finished`之后再发送数据，会怎样？
     
     这个时候由于publisher已经收到了`finished`，
     但是其要追加`otherPassthroughSubject`中的数据，
     所以要在后者所有数据都分发完毕才可以执行前者的receiveCompletion回调，这一点在上面已经得到了验证。
     而`otherPassthroughSubject`的所有数据分发完毕的标志就是其发送`completion`，
     因此，下面会缺少一个log，也就是`<缺少了 completion finished 的log输出>`标识的地方。
     
     ```
     receive subscription: (PassthroughSubject)
     request unlimited
     receive value: (11)
     value 11
     receive value: (21)
     value 21
     receive value: (31)
     value 31
     receive finished
     value 100
     value 200
     <缺少了 completion finished 的log输出>
     ```
     */
    otherPassthroughSubject.send(100)
    otherPassthroughSubject.send(200)
    
    /*:
     如果otherPassthroughSubject发送completion，就标志着其所有的数据都分发完毕了，
     这个时候，原本的pubisher也就会完成整个数据的分发，
     在这之前他会一直缓存要追加的publisher。
     
     发送了completion之后的相关日志如下：
     ```
     ...
     receive finished
     value 100
     value 200
     completion finished
     ```
     */
    otherPassthroughSubject.send(completion: .finished)
    
    /*:
     再做一个测试，在`otherPassthroughSubject`初始化之后就让其分发一个数据，
     也就是上面的`otherPassthroughSubject.send(400)`代码，
     以及在其要追加的publisher要发不completion之前，分发一个数据，
     也就是上面的`otherPassthroughSubject.send(300)`代码。
     
     经过这样穿插的分发数据，会发现这两个数据并没有被追加到publisher中，这是为什么？
     
     前面插入400的那个好理解，publisher还没有来得及对要追加的otherPassthroughSubject进行缓存，因此也不会缓存其已经分发过的数据。
     
     但是后面插入300的那个时机是处于publisher缓存了otherPassthroughSubject之后，
     并且两者都没有发布completion之前，
     按理说应该会将该数据(300)在publisher发送了completion之后也分发出去的，但是结果并没有。
     难道是说这里并没有缓存该数据？
     
     难道是和`PassthroughSubject`本身有关系？毕竟它并不会缓存分发的值。
     */
}

example(of: "prepend & append") {
    
    /*:
     通过上面对`prepend`、`append`这两个操作符的实例，可以总结如下：
     
     * prepend会缓存要前项追加的publisher数据，并且只是添加依赖之后的数据，
     * append也会缓存要追加publisher的数据，并且会
     */
}

example(of: "switchToLatest()") {
    /*:
     `switchToLatest()`会将来自上游的多个数据扁平化，
     使得他们看起来像是从单一publisher分发的数据。
     
     从其名字直译来看：`切换到最新的(publisher)`，
     所以这个操作符处理的源publisher会处理多个publisher，
     并且会在适当的时机切换到最新的publisher。
     
     举个例子，假如有三个不同的pubisher，他们的数据类型都是一样的，
     另一个publisher（称为publishers）的订阅者会接收这三者的数据，并且不会关心是谁分发的数据，
     而publishers只要在某些时刻切换分发的publisher即可。
     
     */

    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()

    let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
    
    publishers
        .print()
        .switchToLatest()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     通过`publishers.send(publisher1)`，将pubishers最新的源切换为`publisher1`，
     因此publisher1分发的数据（1和2）会被publishers分发，对应控制台输出：
     
     ```
     value 1
     value 2
     ```
     
     需要注意的是，在被publishers发送之前，publisher1分发的数据（0）并不会进入publishers中，
     这很好理解，因为它(publisher1)在分发的时候，并不是publishers最新的源。
     */
    publisher1.send(0)
    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)
    
    /*:
     将publishers的源切换为`publisher2`，后者开始分发数据（3），
     同时以前的源publisher1也分发数据（22），
     会发现publisher1分发的数据没有进入到pubishers中，被丢弃了，
     因为当前最新的publisher是`publisher2`。
     
     到这里，对应的控制台输出为：
     
     ```
     value 1    //publisher1分发
     value 2    //publisher1分发
     value 3    //publisher2分发
     value 4    //publisher2分发
     ```
     */
    publishers.send(publisher2)
    publisher1.send(22)
    publisher2.send(3)
    publisher2.send(4)
    
    /*
     切换`publisher3`为pubishers最新的源，
     在其分发数据（5）之后，publishers发送一个`.finished`，
     接着再分发一次数据（6），会发现该数据会被publishers分发给下游订阅者，
     对应的控制台输出为：
     
     ```
     value 1    //publisher1分发
     value 2    //publisher1分发
     value 3    //publisher2分发
     value 4    //publisher2分发
     value 5    //publisher3分发
     value 6    //publisher3分发
     ```
     
     */
    publishers.send(publisher3)
    publisher3.send(5)
    
    publishers.send(completion: .finished)
    
    publisher3.send(6)
    
    /*:
     如果为publishers添加print操作符，可以发现其实已经收到了finished，只不过没有对其进行分发。
     
     接着publisher3分发一个`.finished`，
     这个时候publishers下游订阅者的`receiveCompletion`回调会收到完成的消息。
     
     最后再让publisher3分发一个数据（7），很明显publishers不会对其进行分发。
     
     从上面的示例中可以知道，使用了`switchToLatest()`的Publisher，
     其分发数据的生命周期会依赖于最新的publisher，
     只有在其**自身**和**最新的publisher**都分发了`完成操作`，其才会停止分发数据。
     */
    publisher3.send(completion: .finished)
    
    publisher3.send(7)
}

example(of: "switchToLatest() 2") {
    /*:
     上面列举的publisher分发的是同一种数据类型，总会有要分发不同数据类型的情形，
     这种时候要怎么办呢？
     
     */
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    let publisher3 = PassthroughSubject<Bool, Never>()

    let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
    
    publishers
        .print()
        .switchToLatest()
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)
    
    /*:
     由于publishers初始化的时候设置的是`PassthroughSubject<PassthroughSubject<Int, Never>, Never>`类型，所以只支持分发`Int类型`的数据。
     
     但是将其设置为`PassthroughSubject<AnyPublisher<Any, Never>, Never>`类型也不行，会报错。
     如何破解？

     作为可以解释的通的一点是：
     如果对`Publisher<Publisher<Int, Error>, Never>`类型调用`switchToLatest()`操作符后，
     Combine会将其进行`类型擦除`，对下游订阅者来说，就是`Publisher<Int, Error>`类型，
     因此下游订阅者只会关心收到的Int类型的数据，
     那么如果切换了一个`Publisher<String, Error>`的源，
     由于swift是类型安全的，Combine并不知道要将其变为何种类型，直接抛出编译错误。
     */
//    publishers.send(publisher2)
    
}

example(of: "switchToLatest() 3") {
    /*:
     上面说了针对多种数据类型的Publisher不可以使用`switchToLatest()`进行切换，
     从其方法定义入手，看下Combine是如何定义它的：
     
     ```
     func switchToLatest() -> Publishers.SwitchToLatest<A.Output, Publishers.Merge8<A, B, C, D, E, F, G, H>>
     ```
     会发现这个操作符内部其实是通过`Merge`来实现的，并且最多支持8个Publisher。
     
     我们知道在Combine中，是使用`Publishers命名空间`下，具体的结构体或者类来抽象操作符的，
     `SwitchToLatest`就是对该操作符的抽象，它的声明、泛型约束如下：
     
     ```
     // 省去了Failure的泛型约束
     struct SwitchToLatest<P, Upstream>
     where
     P : Publisher, P == Upstream.Output, Upstream : Publisher
     ```
     
     在这里，P必须要和Upstream的Output类型一致，
     并且要和Merge8中的所有Publisher的Output类型一致。
     放到`switchToLatest()`操作符中就是，所有要切换的Publisher的Output类型都要一致。
     
     */
}
example(of: "combineLatest(_:)") {
    
    /*:
     `combineLatest(_:)`操作符可以将多个publisher的最新数据进行整合，
     然后将组合好的数据进行分发，经过这样的操作，就可以保证所有分发者的数据都是最新的。
     
     整合后的数据会默认会被当做元组进行分发，这一点上不同于`switchToLatest()`操作符，
     因为后者只允许同Output类型的Publisher进行组合处理。
     */
    
    /*:
     由于`(1...5).publisher`在`.combineLatest(_:)`操作符之前就已经完成了所有数据的分发，
     其最后一个数据为`5`，因此组合上`["a","b","c"].publisher`的数据分发，最终的打印log如下：
     
     ```
     value (5, "a")
     value (5, "b")
     value (5, "c")
     ```
     */
    (1...5)
        .publisher
        .combineLatest(["a","b","c"].publisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    let publisher = PassthroughSubject<String, Never>()
    (1...5)
        .publisher
        .print()
        .combineLatest(publisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     `combineLatest(_:)`处理之后的下游订阅者，
     只有在所有的上游发布者都分发了数据才会开始分发数据，
     因此，该操作对应的log如下：
     
     ```
     value (5, "a")
     value (5, "b")
     ```
     */
    publisher.send("a")
    publisher.send("b")
    
    /*:
     并且由于publisher并没有发送finish，
     所以并不会输出`completion finished`，
     执行了下面的代码，对应的log为：
     
     ```
     value (5, "a")
     value (5, "b")
     completion finished
     ```
     
     通过`print()`可以看到，在5之前，是已经收到了1-4的数据，只不过没有对数据进行分发，
     
     ```
     receive value: (1)
     receive value: (2)
     receive value: (3)
     receive value: (4)
     receive value: (5)
     receive finished
     value (5, "a")
     value (5, "b")
     completion finished
     ```
     */
    publisher.send(completion: .finished)
    
    print("test combineLatest with PassthroughSubject")
    
    let aPublisher = PassthroughSubject<Int, Never>()
    let bPublisher = PassthroughSubject<String, Never>()
    
    aPublisher
        .print()
        .combineLatest(bPublisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    aPublisher.send(1)
    aPublisher.send(2)
    
    bPublisher.send("a")
    bPublisher.send("b")
    /*:
     上面的操作可以正常的在控制台输出：
     
     ```
     value (2, "a")
     value (2, "b")
     ```
     
     假如这个时候将aPublisher发送`.finished`，然后bPublisher继续分发数据，会怎样呢？
     */
    
    aPublisher.send(completion: .finished)
    bPublisher.send("c")
    
    /*:
     竟然还会继续合并两个publisher的数据，相关的输出为：
     
     ```
     value (2, "a")
     value (2, "b")
     value (2, "c")
     ```
     并且发现，监听aPublisher完成的`receiveCompletion`回调也没有走。
     
     那么，如果让bPublisher也发送一个`.finished`呢？
     */
    
    bPublisher.send(completion: .finished)
    
    /*:
     会发现，这个时候aPublisher的完成回调才走了。
     
     这很好理解，因为`combineLastest`操作符会缓存其相关的publisher，
     这是一个持续性的等待过程，直到**所有相关的publisher**都完成为止。
     因此，原publisher会等到添加在它身上的其他所有publisher都完成之后才会完成。
     */
}

example(of: "merge(with:)") {
    
    /*:
     上面提到了Merge这个结构体抽象的操作符，其中一个就是`merge(with:)`，
     这个操作符允许合并另一个publisher的数据进行分发
     */
    let aPublisher = PassthroughSubject<Int, Never>()
    let bPublisher = PassthroughSubject<Int, Never>()
    
    aPublisher
        .merge(with: bPublisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    /*:
     aPublisher通过合并bPublisher，
     作为aPublisher的订阅者就可以收到两者先后分发的数据，
     相当于将bPublisher要分发的数据插入到aPublisher中。
     
     相关控制台的输出为：
     
     ```
     value 1    // from aPublisher
     value 2    // from aPublisher
     value 33   // from bPublisher
     value 4    // from aPublisher
     value 5    // from aPublisher
     ```
     */
    aPublisher.send(1)
    aPublisher.send(2)
    
    bPublisher.send(33)
    
    aPublisher.send(4)
    aPublisher.send(5)
    
    /*:
     `merge(with:)`还有一系列的变种操作符，用于支持多个Publisher，目前最多支持8个。
     */
//    let cPublisher = PassthroughSubject<Int, Never>()
//    cPublisher
//    .merge(with: <#T##Publisher#>, <#T##c: Publisher##Publisher#>, <#T##d: Publisher##Publisher#>, <#T##e: Publisher##Publisher#>, <#T##f: Publisher##Publisher#>, <#T##g: Publisher##Publisher#>, <#T##h: Publisher##Publisher#>)
}

example(of: "zip(_:)") {
    /*:
     和`combineLatest(_:)`操作符一样，
     `zip(_:)`操作符也支持对不同Output类型的Publisher进行组合操作，
     并且都是使用元组组合后进行分发。
     所不同的是，`zip`会将要组合的Publisher进行一对一的组合，
     而不是将他们最新的数据进行组合。
     
     zip本意是指拉链，压缩是另一种解释，用拉链来解释这个操作符会更直观一些，
     两个publisher分发的数据一一对应，就相当于拉链中两个相互咬合的齿。
     */
    
    let aPublisher = PassthroughSubject<Int, Never>()
    let bPublisher = PassthroughSubject<String, Never>()
    
    aPublisher
        .zip(bPublisher)
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    aPublisher.send(1)
    aPublisher.send(2)
    
    bPublisher.send("three")
    bPublisher.send("four")
    
    /*:
     到目前为止，`aPublisher`和`bPublisher`都分发了2个数据：1和2、three和four，
     对应的控制台输出为：
     
     ```
     value (1, "three")
     value (2, "four")
     ```
     
     可以看出来，经过zip处理过后的数据以`aPublisher`和`bPublisher`先后分发的顺序成组交给了订阅者。
     */
    aPublisher.send(5)
    aPublisher.send(6)
    aPublisher.send(7)
    
    /*:
     接着再让`aPublisher`分发数据，而`bPublisher`不分发，
     会发现到这里，控制台并没有多余的输出。
     这很好解释，因为`bPublisher`并没有最新的数据要分发，
     而zip是需要将组合中所有Publisher的数据进行一一对应进行分发。
     */
    
    bPublisher.send("eight")
    bPublisher.send("nine")
    
    /*:
     接着让`bPublisher`开始分发数据，这个时候控制台对应的输出为：
     
     ```
     value (1, "three")
     value (2, "four")
     value (5, "eight")
     value (6, "nine")
     ```
     这时，两个Publisher的数据别按照预期的结果进行了分发。
     */
}

example(of: "zip(_:) 2") {
    /*:
     `zip(_:)`支持对组合的Publisher进行数据的转换，
     对应的变种操作符为：`zip(_:, transform:)`，
     在`transform`的block回调中可以对组合的数据进行处理。
     
     不仅可以对数据进行处理，还可以将数据进行类型转换，
     由于通过zip处理的数据会以元组进行分发，所以这里相当于修改了元组的数据类型，并没有修改元组的长度。
     */
    
    let aPublisher = PassthroughSubject<Int, Never>()
    let bPublisher = PassthroughSubject<String, Never>()
    
    aPublisher
        //: 这里可以将aPublisher分发的Int类型修改为String类型
        .zip(bPublisher, { (a, b) -> (String, String) in
            return ("\(a)", "transformed: \(b)")
        })
        .sink(receiveCompletion: {print("completion \($0)")},
              receiveValue: {print("value \($0)")})
        .store(in: &subscriptions)
    
    aPublisher.send(1)
    aPublisher.send(2)
    
    bPublisher.send("three")
    bPublisher.send("four")
    
    /*:
     除了增加了transform的变种，zip还有对于Publisher数量的变种，
     不过最多支持2个，着实有点儿寒碜。
     */
}

//: [Next](@next)
