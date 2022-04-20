 
import Foundation
import KakaJSON

class BaseModel: NSObject, Convertible {
    
    func kj_modelKey(from property: Property) -> ModelPropertyKey {
        return property.name
    }
    
    required override init() {
        
    }
    
    /// json解析
    static public func jsonObject(json: String) -> Any? {
        guard let data = json.data(using: .utf8) else { return nil }
        let object = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return object
    }
    
}


class RequestError: Error {
    
    var code = ""
    var data = ""
    var message = ""
    
    init(code: String, data: String, message: String) {
        self.code = code
        self.data = data
        self.message = message
    }
    
}

class RequestResultModel<T: Convertible>: BaseModel {
    
    var code = ""
    /// 解密后的json, 如果T是RequestStringModel则是后台返回的参数
    var data = ""
    var msg = ""
    var sign = ""
    
    // MARK: - 本地使用
    
    /// 解析数据格式[key: value]
    var model: T?
    /// 解析数据格式[[key: value]]
    var modelArray: [T]?
    
    /// 是否请求成功
    var isSuccess: Bool {
        get {
            return code == "200"
        }
    }
    
    /// 把json解析成model
    func pasringModel() {
        // RequestStringModel 字符串数据不必再解析, 数据在data
//        guard !stringIsEmpty(str: data),
//              T.self != RequestStringModel.self else {
//            return
//        }
        // 解析model或者modelArray
        let obj = BaseModel.jsonObject(json: data)
        if obj is [String: Any] {
            model = data.kj.model(T.self)
        } else if obj is [[String: Any]] {
            modelArray = data.kj.modelArray(T.self)
        }
    }
    
    /// 把json解析成model
    func pasring(json: [String: Any]) {
        
        let obj = json["data"]
        
        if let code = json["code"] {
            self.code = "\(code)"
        }
        if let data = json["data"] {
            self.data = "\(data)"
        }
        if let msg = json["msg"] {
            self.msg = "\(msg)"
        }
        if let sign = json["sign"] {
            self.sign = "\(sign)"
        }
        
        if obj is [String: Any] {
            model = (obj as! [String: Any]).kj.model(T.self)
        } else if obj is [[String: Any]] {
            modelArray = (obj as! [[String: Any]]).kj.modelArray(T.self)
        } else if obj is String {
            self.pasringModel()
        }
    }
    
}

/// 不需要解析数据 或者 需要解析的数据是字符串 用这个model
class RequestStringModel: BaseModel {
    
}

/// 回复消息类型
enum CommentContentType: Int, ConvertibleEnum{
    case text = 1
    case image = 2
    case replay
}

class CommentModel: BaseModel {
    // 文本内容
    var content: String = ""
    // 创建时间
    var createTime: String = ""
    // 是否点赞 0否
    var isLike: Bool = false
    // 点赞数量
    var likeNum: String = ""
    // 链接内容
    var linkContent: String = ""
    // 资讯no
    var newsNo: String = ""
    // 用户昵称
    var nickname: String = ""
    // 消息id
    var no: String = ""
    // 头像
    var head: String = ""
    // 类型(预留)
    var contentType: CommentContentType = .text
    // 类型(1正常消息,2回复消息,3删除单条消息,4屏蔽信息,5解除屏蔽信息)
    var type: String = ""
    // 用户id
    var userId: String = ""
    
    // 指向文本内容
    var referContent: String = ""
    // 指向 类型(预留)
    var referContentType: CommentContentType = .text
    // 指向头像
    var referHead: String = ""
    // 指向的消息id
    var referMsgNo: String = ""
    // 指向回复是否删除 0 否
    var referIsDel: Bool = false
    // 指向 链接内容(json格式)
    var referLinkContent: String = ""
    // 指向用户昵称
    var referNickname: String = ""
    // 被指向的用户id
    var referUserId: String = ""
    
    var commentType: CommentContentType {
        get {
            if type == "2" {
                return .replay
            } else {
                return contentType
            }
        }
    }
    
    lazy var media: MediaModel? = {
        guard let json = BaseModel.jsonObject(json: linkContent) as? Dictionary<String, Any> else {
            return nil
        }
        let model = json.kj.model(MediaModel.self)
        return model
    }()
    
    lazy var replayContent: ReplayModel = {
        let model = ReplayModel()
        model.content = referContent
        guard let json = BaseModel.jsonObject(json: referLinkContent) as? Dictionary<String, Any> else {
            return model
        }
        model.media = json.kj.model(MediaModel.self)
        return model
    }()
    
}

let kChatImageMaxWidth: CGFloat = 126 //最大的图片宽度
let kChatImageMinWidth: CGFloat = 50 //最小的图片宽度
let kChatImageMaxHeight: CGFloat = 150 //最大的图片高度
let kChatImageMinHeight: CGFloat = 95 //最小的图片高度

class MediaModel: BaseModel {
    var cover: String = ""
    var high: CGFloat = 0
    var width: CGFloat = 0
    var links: String = ""
    var times: Int = 0
    var type: Int = 0
    
    /**
     获取缩略图的尺寸
     
     - parameter originalSize: 原始图的尺寸 size
     
     - returns: 返回的缩略图尺寸
     */
    class func getThumbImageSize(_ originalSize: CGSize) -> CGSize {
        
        let imageRealHeight = originalSize.height
        let imageRealWidth = originalSize.width
        
        var resizeThumbWidth: CGFloat
        var resizeThumbHeight: CGFloat
        /**
        *  1）如果图片的高度 >= 图片的宽度 , 高度就是最大的高度，宽度等比
        *  2）如果图片的高度 < 图片的宽度 , 以宽度来做等比，算出高度
        */
        if imageRealHeight >= imageRealWidth {
            let scaleWidth = imageRealWidth * kChatImageMaxHeight / imageRealHeight
            resizeThumbWidth = (scaleWidth > kChatImageMinWidth) ? scaleWidth : kChatImageMinWidth
            resizeThumbHeight = kChatImageMaxHeight
        } else {
            let scaleHeight = imageRealHeight * kChatImageMaxWidth / imageRealWidth
            resizeThumbHeight = (scaleHeight > kChatImageMinHeight) ? scaleHeight : kChatImageMinHeight
            resizeThumbWidth = kChatImageMaxWidth
        }
        
        return CGSize(width: resizeThumbWidth, height: resizeThumbHeight)
    }
}


class ReplayModel: BaseModel {
    var content: String = ""
    var media: MediaModel?
    
    func isTextMessage() -> Bool {
//        if stringIsEmpty(str: content) {
//            return false
//        }
        return true
    }
}


