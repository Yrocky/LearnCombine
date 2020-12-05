import Foundation

public struct AnyHuman_: Human {
    
    fileprivate let _base: Human
    
    public var base: Any {
        return self._base
    }
    
    public init<Base: Human>(_ base : Base) {
        // 如果是根据一个`AnyHuman`来创建`AnyHuman`，直接使用
        if let anyHuman = base as? AnyHuman_ {
            self = anyHuman
        } else {
            self._base = base
        }
    }
    /*:
     AnyHuman_同样和Human具备一样的行为，
     但是内部并不将行为使用私有的box来转发，
     而是自己来完成转发，
     通过初始化的时候存储的`_base`来转发。
     */
    public func speak() {
        _base.speak()
    }
    
    public func run() {
        _base.run()
    }
    
    public func see() {
        _base.see()
    }
}
