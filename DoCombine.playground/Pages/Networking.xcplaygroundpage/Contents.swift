//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

var subscriptions = Set<AnyCancellable>()

/*:
 作为开发者，日常工作大多都是围绕网络请求来完成的，
 使用网络框架（URLSession）从服务端获取到数据（一般为json），然后经过处理展示到ui上。
 
 当然并不是所有的网络请求都是获取一段json，还有诸如：下载、上传、WebSocket、流等等。
 */

let url = URL(string: "https://v2.sohu.com/article-service-api/article/421252230_120126853")!
    
/*:
 Combine为`URLSession`拓展了一些方法，使得他可以创建一个Publisher，
 一共有两个：`.dataTaskPublisher(for: URL)`和`.dataTaskPublisher(for: URLRequest)`，
 */

URLSession.shared
    .dataTaskPublisher(for: url)
    .sink(receiveCompletion: {print("completion \($0)")},
          receiveValue: {print("json: \($0)")})
    .store(in: &subscriptions)

/*:
 通过`receiveValue`中的打印可以知道通过`dataTaskPublisher(for:)`处理之后的数据，
 会以一个元组的形式下发给订阅者，
 元组有两个值：`data`、`response`，分别为`Data`、`URLResponse`类型：
 
 ```
 (data: 6362 bytes, response: <NSHTTPURLResponse: 0x600000a0fa20>...)
 ```
 */

URLSession.shared
    .dataTaskPublisher(for: url)
    .sink(receiveCompletion: {print("completion \($0)")},
          //: 因此这里直接使用元组中的两个数据
          receiveValue: { data, response in
//            print("data:\(data.count) response:\(String(describing: response.url))")
    })
    .store(in: &subscriptions)

/*:
 经过网络请求获取到的是Data类型的，我们需要进一步对其进行转化，
 将Data转成对应的模型（Array、Dictionary、Custom-like）。
 */

struct MyResponse: Codable {
    let code: Int
//    let msg: String
//    let data: Dictionary<String, Any>

    private enum CodingKeys: CodingKey {
        case code
//        case msg
//        case data
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
//        try container.encode(msg, forKey: .msg)
//        try container.encode(data, forKey: .data)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
//        msg = try container.decode(String.self, forKey: .msg)
    }
}

URLSession.shared
    .dataTaskPublisher(for: url)
    //: 1.可以直接使用`tryMap`来进行数据映射解析
//    .tryMap{ data, _ in
//        try JSONDecoder().decode(MyResponse.self, from: data)
//    }
    /*:
     2.还可以先将`元组`数据经过`map`变成`Data`类型的数据，
     然后使用`decode(type:,decoder:)`进行映射解析
     */
    .map(\.data)
    .decode(type: MyResponse.self, decoder: JSONDecoder())
    
    .sink(receiveCompletion: {print("completion \($0)")},
      //: 因此这里直接使用元组中的两个数据
        receiveValue: { response in
            print("my response \(response.code)")
    })
    .store(in: &subscriptions)


// 服务器返回的数据对应的Model
struct NewsModel: Codable {
    var reason: String
    var error_code: Int
    var result:Result
}

struct Result: Codable {
    var stat: String
    var data:[DataItem]
}

// 实现Hashable，List中的数据必须实现
struct DataItem: Codable, Hashable {
    var title: String
    var date: String
    var category: String
    var author_name: String
    var url: String
}

let url3 = URL(string: "http://v.juhe.cn/toutiao/index?type=top&key=d1287290b45a69656de361382bc56dcd")
let request = URLRequest(url: url3!)
let session = URLSession.shared
let backgroundQueue = DispatchQueue.global()

let dataPublisher = session.dataTaskPublisher(for: request)
    .retry(5)
    .timeout(5, scheduler: backgroundQueue)
    .map{$0.data}
    .decode(type: NewsModel.self, decoder: JSONDecoder())
    .subscribe(on: backgroundQueue)
    .eraseToAnyPublisher()

let subscription = dataPublisher.receive(on: DispatchQueue.main)
    .sink(receiveCompletion: {_ in }) {
        newsModel in
        print(newsModel.result.data)
}

//: [Next](@next)
