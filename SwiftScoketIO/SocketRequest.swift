//
//  SocketRequest.swift
//  SwiftScoketIO
//
//  Created by Debug.s on 2022/4/20.
//

import UIKit
import PromiseKit
class SocketRequest {

    /// 加入
    static public func join() -> Promise<RequestResultModel<RequestStringModel>> {
        return SocketUtil.share.send(.join)
    }
    
    /// 离开
    static public func leave() -> Promise<RequestResultModel<RequestStringModel>> {
        return SocketUtil.share.send(.leave)
    }
    
    //发表评论
    static func sendComment(model: CommentModel) -> Promise<RequestResultModel<CommentModel>> {
        return SocketUtil.share.sendComment(model: model)
    }
}
