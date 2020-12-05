import Foundation

public struct AnyHuman: Human {
    
    fileprivate let box: AnyHumanBox
    
    public var base: Any {
        return self.box.base
    }
    
    public init<Base: Human>(_ base : Base) {
        // 如果是根据一个`AnyHuman`来创建`AnyHuman`，直接使用
        if let anyHuman = base as? AnyHuman {
            self = anyHuman
        } else {
            // 否则就使用box来做中转
            box = HumanBox(base)
        }
    }
    /*:
     AnyHuman 是一个具体的类型，可以是struct，也可以是class，
     他必须和Human协议的行为保持一致，同时其内部的box也需要和Human的行为保持一致，
     这样才可以将box作为一个中转来使用。
     */
    public func speak() {
        box.speak()
    }
    
    public func run() {
        box.run()
    }
    
    public func see() {
        box.see()
    }
}

fileprivate protocol AnyHumanBox: Human {
    
    var base: Any { get }
}

fileprivate struct HumanBox<Base: Human>: AnyHumanBox {
    
    private let _base: Base
    
    var base: Any {
        return _base
    }
    
    init(_ base: Base) {
        self._base = base
    }
    
    func speak() {
        _base.speak()
    }
    
    func run() {
        _base.run()
    }
    
    func see() {
        _base.see()
    }
}
