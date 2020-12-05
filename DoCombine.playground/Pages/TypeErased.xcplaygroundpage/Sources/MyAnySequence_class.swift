import Foundation

/*:
 我们需要在不公开类型信息的情况下，从多个类型中包装出来一些公共的功能，
 其实就是使用父类作为一个公共接口，具体的实现交给子类。
 
 父类暴露 API 出来，子类根据具体的类型信息来做具体的实现。
 */
public class MyAnySequence_class<E>: Sequence {
    
    public class Iterator: IteratorProtocol {
        public typealias Element = E
        
        public func next() -> Element? {
            fatalError("must override next()")
        }
    }
    
    public func makeIterator() -> Iterator{
        fatalError("must override makeIterator()")
    }
}

private class MyAnySequenceImpl_class<S: Sequence>: MyAnySequence_class<S.Element> {
    
    class IteratorImpl: Iterator {
        var wrapped: S.Iterator
        
        init(_ wrapped: S.Iterator) {
            self.wrapped = wrapped
        }
        
        override func next() -> S.Element? {
            wrapped.next()
        }
    }
    
    var s: S
    
    init(_ s: S) {
        self.s = s
    }
    
    override func makeIterator() -> Iterator {
        return IteratorImpl(s.makeIterator())
    }
}

public extension MyAnySequence_class {
    static func make<S>(_ s: S) -> MyAnySequence_class<S.Element> where S: Sequence {
        return MyAnySequenceImpl_class(s)
    }
}

public extension Sequence {
    func eraseToMyAnySequence() -> MyAnySequence_class<Self.Element> {
        return MyAnySequenceImpl_class(self)
    }
}
