//: [Previous](@previous)

import Foundation
import UIKit

var str = "Hello, playground"

/*:
 
 ## 引子
 
 虽然Combine是闭源的，但是响应式框架的思想是相通的，Combine也只不过是基于这个思想，实现了一套接口不同于RxSwift的框架，内部可能会有一些特殊处理或者私有黑魔法，但是两者殊途同归。另外，苹果一贯的做法就是不兼容老版本，新框架只有新版本可以使用，但是正常的业务开发是不可能只有一个版本的，都会往前推至少3个版本，等到真正全面的用上Combine的时候，那也都是3-4年之后了，因此一些社区开源实现就是一个不错的选择。
 
 社区的开源不仅能为业务提供最新技术的支持，也可以帮助我们来学习或者窥探下Combine的内部实现机制。另外要说的一点是，虽然开源项目是一个不错的选择，但是有些项目由于时间人员的原因会停止更新，导致遗留的问题无法解决，所以在实际项目中还是要谨慎使用，学习就另说了。
 
 接下来我们将从基础的Publisher、Subscribe、Subscription入手，看下经典的数据传递流程，之后会以开源实现的视角再次学习一下Backpressure，最后挑选几个操作符来看下他们是如何实现的。
 
 here we go！
 
 ## 从Publisher到Subscriber
 
 
 ## Backpressure
 
 
 ## Operators
 
 */
/*:
 * [CombineX](https://github.com/cx-org/CombineX)
 */
//: [Next](@next)


class Person {
    
    struct State {
        var name: String?
        var isOpenDetails = false
    }
    /*:
     因为State是结构体，属于值变量，
     只要他的属性有变动就等同于这个state属性有变动，
     这时候就会调用render，重新渲染
     */
    var state = State() {
        didSet { render() }
    }
    
    func render() {
        print("render...")
    }
}


let me = Person()
me.state.name = "rocky"
me.state.isOpenDetails = true

var state = Person.State()
state.name = "Rocky"
me.state = state

class ModelY: ObservableObject {
    
    var color: String = "red"
    
    var money: Int = 0 {
        didSet{ updateUI() }
    }
    
    var address: String = "" {
        didSet { updateUI() }
    }
    
    @Published var host: String = ""
    
    func updateUI() {
        objectWillChange.send()
    }
}

let modelY = ModelY()

modelY
    .objectWillChange
    .print("[ModelY]")
    .sink {
        print("modelY did change \($0)")
    }

//modelY.money = 34
//modelY.address = "SH"
//modelY.host = "rocky"
modelY.color = "white"

class ModelYView: UIView {
    
    var modelY = ModelY()
    let modelYDesLabel = UILabel()
    let modifColorButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        modifColorButton.frame = CGRect(origin: .zero, size: CGSize(width: 80, height: 50))
        modifColorButton.setTitle("color", for: .normal)
        modifColorButton.addTarget(self, action: #selector(modifColor), for: .touchUpInside)
        addSubview(modifColorButton)
        
        modelYDesLabel.frame = CGRect(origin: CGPoint(x: 0, y: 150), size: CGSize(width: 300, height: 50))
        modelYDesLabel.text = "color:\(modelY.color)\n money:\(modelY.money)\n host:\(modelY.host)"
        addSubview(modelYDesLabel)
    }
    
    @objc func modifColor() {
        modelY.color = "orange"
        updateUI()
    }
    
    @objc func modifMoney() {
        modelY.money = 34
        updateUI()
    }
    
    func updateUI() {
        modelYDesLabel.text = "color:\(modelY.color)\nmoney:\(modelY.money)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let modelYView = ModelYView()
modelYView.backgroundColor = .red
modelYView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 500))

