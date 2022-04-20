//
//  ViewController.swift
//  SwiftScoketIO
//
//  Created by Debug.s on 2022/4/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //加入聊天室
        _ = SocketUtil.share.joinCommentPool(newsNo: "noID")
                    
        // MARK: - scoket 实时评论功能
        // 添加监听 收到新评论
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCommentSuccess(notif:)), name: ReceiveCommentSuccess, object: nil)
     
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
           sendMsg()
    }
    
    @objc func receiveCommentSuccess(notif: Notification) {
        DispatchQueue.main.async {
            guard let model = notif.object as? CommentModel else { return }
            if  (model.type == "1" || model.type == "2") {
                // 发消息或回复消息 code
                
            } else if  model.type == "3" {
                // 删除消息 code
                
            }
        }
    }
    
    //发送评论
    func sendMsg(){
        let model = CommentModel()
        model.contentType = .image
        model.linkContent = "回复的图片消息体"
        model.content = "准备发送过来啦"
        SocketRequest.sendComment(model: model).done {  result in
            let newModel = result.model
            model.no = newModel?.no ?? ""
            print("评论成功 no ---- \(model.no)")
        }.catch { error in
            print("失败了")
        }.finally {
            print("请求完成")
        }
    }

   
     
}

