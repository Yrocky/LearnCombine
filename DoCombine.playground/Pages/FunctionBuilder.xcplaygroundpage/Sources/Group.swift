import Foundation

// MARK: Function Builder
@_functionBuilder
public struct NodeBuilder {

    public static func buildBlock() -> [Nodeable] {
        EmptyNode().buildNodes()
    }
    
    //: 当我们实现了下面的三个方法来允许Group最多接收3个参数之后，会发现并不可以使用if-else语句
//    public static func buildBlock(_ n: Nodeable) -> NodeBuilder {
//        NodeBuilder(n)
//    }
//
//    public static func buildBlock(_ n0: Nodeable, _ n1: Nodeable) -> NodeBuilder {
//        NodeBuilder(n0, n1)
//    }
//
//    public static func buildBlock(_ n0: Nodeable, _ n1: Nodeable, _ n2: Nodeable) -> NodeBuilder {
//        NodeBuilder(n0, n1, n2)
//    }
    
    //: 或者我们直接使用可变参数来实现多个参数的功能，但是这样就不能限制数量了
    public static func buildBlock(_ nodes: Nodeable...) -> [Nodeable] {
        nodes
    }
    
    /*:
     要支持if-else语句，需要再实现3个方法，
     除了if-else，还有ForEach等语句，但是需要实现`buildDo`、`buildArray`等方法
     */
    
    @inlinable
    public static func buildIf(_ n: Nodeable?) -> Nodeable {
        n ?? EmptyNode()
    }

    @inlinable
    public static func buildEither(first: Nodeable) -> Nodeable {
        first
    }

    @inlinable
    public static func buildEither(second: Nodeable) -> Nodeable {
        second
    }
}

// MARK: Nodeable

public protocol Nodeable {
    func buildNodes() -> [Nodeable]
}

extension Nodeable {
    public func buildNodes() -> [Nodeable] {
        return [self]
    }
}

extension Optional: Nodeable where Wrapped: Nodeable {
    /// Build an array of cell.
    @inlinable
    public func buildNodes() -> [Nodeable] {
        return self?.buildNodes() ?? []
    }
}

// MARK: EmptyNode
//: 创建一个空的Node，为了在`if`中使用
public struct EmptyNode: Nodeable {
    
    public init() { }
    
    public func buildNodes() -> [Nodeable] {
        []
    }
}

// MARK: Cell

public struct Cell {
    
    public var text: String
    
    public init(_ text: String) {
        self.text = text
    }
}

extension Cell: Nodeable{}

// MARK: Group

public struct Group<Node> {
    
    public var nodes: [Node]
}

public extension Group where Node == Nodeable {
    
    init(@NodeBuilder _ builder: () -> Node) {
        nodes = builder().buildNodes().compactMap{ $0 }
    }
    
    init<S: Sequence>(of data:S, node: (S.Element) -> Node) {
        nodes = data.flatMap { element in
            node(element).buildNodes()
        }
    }
}

let g = Group {
    Cell("Hello")
    Cell("World")
    Cell("~")
}

let aaaa = Group {

}

let ggg = Group(of: ["a","b","c"]) {
    Cell($0)
}

let can = false

let gg = Group {
    Cell("Hello")
    Cell("World")
//    if can {
        Cell("~")
//    }
}
