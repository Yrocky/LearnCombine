# Transforming operators

在Combine中，`操作符`是除了`Publisher`和`Subscriber`之外，最重要的部分。

对****来自Publisher的值****进行****操作****的方法称为`操作符`，并且每一个操作符的结果都是返回一个`新的Publisher`，操作符接收`upstream`，并对数据进行加工处理，然后将结果作为`downstream`交给下一个操作符，在加工处理的过程中有可能会产生错误，所以，交给下一个操作符的还可能是error，这个时候就需要使用`try-like`变种的操作符来处理对应的数据。

## collect()

`collect()`操作符可以将从Publisher发出的单个值转化成数组，

``` swift
let array = ["a","b","c","d","e"]
//: 前面我们知道了Combine为Array提供了便利创建Publisher的方法，
array
    .publisher
    .collect()
    .sink { print("receive \($0)") }
    .store(in: &subscriptions)
```

普通的但是这样只能让元素一个一个的输出，如果想让元素以`一定个数成组`输出就可以使用collect。在成组中可以直接设置`count`，让数据以一定的个数成组输出；还可以使用一个`TimeGroupingStrategy`的enum来指定成组策略，策略可以使按照`time`的，还可以是按照`timeOrCount`的。

需要注意的是，通过collect操作符处理之后得到的数据类型将是一个Array。
