//
//  SocketUtil.swift
//  SwiftScoketIO
//
//  Created by Debug.s on 2022/4/20.
//

import UIKit
import SocketIO
import PromiseKit
import KakaJSON
 

// 自定义Log
public func PLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
#if DEBUG
    let fileName = (file as NSString).lastPathComponent;
    print("🔨 [文件名：\(fileName)], [方法：\(funcName)], [行数：\(lineNum)]\n🔨 \(message)");
#endif
}

enum SocketSendEvent: String {
   // 连接socket事件
   case join = "join"
   // 断开socket事件
   case leave = "leave"
   // 发送评论
   case sendMsg = "sendMsg"
}

enum SocketReceiveEvent: String {
   // 接收评论
   case sendMsg = "sendMsg"
}
    
/// 接收评论
public let ReceiveCommentSuccess = NSNotification.Name("ReceiveCommentSuccess")



class SocketUtil {
    //您的socket服务地址
    let WSURL = URL(string: "http:www.baidu.com")
    static let share = SocketUtil()
    private var manager:SocketManager?
    private var socket:SocketIOClient?
    // [] 里面传递需要的字段 ，比如版本号  [ "h": HttpRequestUtil.share.platformVersion]
    private var socketHeaders : [String:String] = [:]
    private var config:SocketIOClientConfiguration = []
      
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /// 已经进入前台
    @objc func willEnterForeground() {
        
    }
     
    /// 已经进入后台
    @objc private func didEnterBackground() {
        
    }
    //  MARK: - Public
    
    /// 连接socket
    public func connect(){
        if manager != nil {
            //断开连接
            disconnect()
        }
        
        socketHeaders["t"] = "用户token"
        socketHeaders["isEnabled"] = "false"
        config = [
            .log(true),//打印日志
            .compress,
            .extraHeaders(socketHeaders),
            .reconnects(true), //是否重连机制
            .reconnectWaitMax(7) //重新连接等待最大秒数
        ]
        
        manager = SocketManager(socketURL: WSURL!, config: config)
        socket = manager?.defaultSocket
        listeningStatus()
        listeningMsgEvent()
        socket?.connect()
        
    }
    /// 获取状态
    public func getConnectStatus() -> SocketIOStatus {
        return self.socket?.status ?? .disconnected
    }
    
    /// 断开连接
    public func disconnect() {
        SocketRequest.leave().done { result in

        }.catch { error in

        }.finally {
            self.manager?.disconnect()
            self.manager = nil
            self.socket = nil
        }
    }
    
    /// 更新请求头
    public func updateHeaders(name: String, value: String) {
        socketHeaders[name] = value
        config = [
            .log(false),
            .compress,
            .extraHeaders(socketHeaders),
            .reconnects(true),
            .reconnectWaitMax(7)
        ]
        manager?.setConfigs(config)
    }
    
    /// 解析json
    private func parsingJson<T: Convertible>(_ json: [String: Any]) -> RequestResultModel<T> {
         
       
        //转换model 返回model
        let resultModel = json.kj.model(RequestResultModel<T>.self)
        // 解密
        resultModel.data = "解密后的data"
        //转model
        resultModel.pasringModel()
        return resultModel
    }
    
}


extension SocketUtil {
    
    /// 监听scoket状态变化
    private func listeningStatus() {
        
        socket?.on(clientEvent: .statusChange) { data, ack in
            
            guard let status = data.first as? SocketIOStatus else {
                return
            }
            
            PLog("socket status change: \(status)")
            
            if status == .connected {
//                _ = SocketRequest.join().done { result in }
            } else if status == .disconnected {
                let state = UIApplication.shared.applicationState
                if (state != .background) {
//                    if UserUtil.share.isLogin() {
                    //登陆情况下直接重连
                        self.reconnect()
//                    }
                }
            }
        }
        
        socket?.on(clientEvent: .error) { data, ack in
            PLog("socket error: \(data)")
        }
        
    }
    
    // MARK: - Private
    
    /// 重新连接
    private func reconnect() {
        
        guard let socket = socket else {
            return
        }
        
        guard socket.status != .connected && socket.status != .connecting else {
            return
        }
        
        manager?.reconnect()
    }
    
    /// 监听所有消息事件
    private func listeningMsgEvent() {
        
        // MARK: - 监听评论
        socket?.on(SocketReceiveEvent.sendMsg.rawValue) { data, ack in
            let ids = self.handleData(data, evenName: .sendMsg)
//            if !stringIsEmpty(str: ids) {
                ack.with(ids)
//            }
        }
        
    }
    
    /// 处理下发的数据, 返回需要回调的id
    private func handleData(_ data: [Any], evenName: SocketReceiveEvent) -> String {
        
        // 解析数据
        guard let reponse = data.first as? String else {
            return ""
        }
        guard let json = BaseModel.jsonObject(json: reponse) as? [String : Any] else {
            return ""
        }
        
        // TODO: 存数据库
        // 处理事件
        if evenName == .sendMsg {
            
            let result: RequestResultModel<CommentModel> = self.parsingJson(json)
            
            // 后台code!=200, 走错误处理
            guard result.isSuccess else {
                return ""
            }
            
            guard let serverModel = result.model else {
                return ""
            }
            
            // 更新频道/聊天室会话列表
            if serverModel.type == "1" || serverModel.type == "2" {
                // 正常消息 跟 回复消息
                NotificationCenter.default.post(name: ReceiveCommentSuccess, object: serverModel, userInfo: nil)
            } else if serverModel.type == "3" {
                // 删除消息
            }
            
            print("收到消息=== \(json)")
            
            return paramsEncrypt(parameters: ["no": serverModel.no])
        }
        return paramsEncrypt(parameters: ["no": ""])
    }
    
    /// 参数加密
    private func paramsEncrypt(parameters: Any?) -> String {
        
       //parameters转为string - > rsa 加密
        
        return "rsa加密后的参数"
    }

}

extension SocketUtil {
    
    /// 发送消息
    public func send<T: Convertible>(_ msgEvent: SocketSendEvent, params: [String: Any]? = nil) -> Promise<RequestResultModel<T>> {
        
        let paramsStr = paramsEncrypt(parameters: params)
        
        // 返回 Promise
        return Promise<RequestResultModel<T>> { resolver in
            // 发送socket事件
            socket?.emitWithAck(msgEvent.rawValue, paramsStr).timingOut(after: 5) { data in
                // 请求超时
                if data.first as? String ?? "passed" == SocketAckStatus.noAck.rawValue {
                    resolver.reject(RequestError(code: "错误码", data: "", message: "Timeout"))
                    return
                }
                
                // 解析数据
                guard let json = data.first as? String,
                      let jsonObject = BaseModel.jsonObject(json: json) as? [String: Any] else {
                    resolver.reject(RequestError(code: "错误码", data: "", message: "Data parsing error"))
                    return
                }
                
                let resultModel: RequestResultModel<T> = self.parsingJson(jsonObject)
                // 后台code!=200, 走错误处理
                guard resultModel.isSuccess else {
                    resolver.reject(RequestError(code: resultModel.code, data: resultModel.data, message: resultModel.msg))
                    return
                }
                
                resolver.fulfill(resultModel)
            }
        }
    }
    
    /// 加入资讯评论
    public func joinCommentPool(newsNo: String) ->Promise<RequestResultModel<RequestStringModel>> {
        return SocketUtil.share.send(.join, params: ["newsNo": newsNo])
    }
    
    /// 离开资讯评论
    public func leaveCommentPool(newsNo: String) ->Promise<RequestResultModel<RequestStringModel>> {
        return SocketUtil.share.send(.leave)
    }
    
    /// 评论。回复评论
    public func sendComment(model: CommentModel) -> Promise<RequestResultModel<CommentModel>> {
        if SocketUtil.share.getConnectStatus() != .connected {
            self.reconnect()
            return Promise<RequestResultModel<CommentModel>> { resolver in
                resolver.reject(RequestError(code: "错误码", data: "", message: "Socket has disconnected"))
            }
        }
        var dic : [String: Any] = [:]
        dic["newsNo"] = model.newsNo
        dic["appId"] = "APPID"
        //... 或者加入其他参数
        return SocketUtil.share.send(.sendMsg, params: dic)
    }
    
}

