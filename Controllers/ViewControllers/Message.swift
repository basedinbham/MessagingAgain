//
//  Message.swift
//  MessagingAgain
//
//  Created by Kyle Warren on 9/17/21.
//

import Foundation
import UIKit
import Firebase
import MessageKit

struct Message {
    var id: String
    var content: String
    var created: Timestamp
    var senderID: String
    var senderName: String
    // Dictionary returning values of variables
    var dictionary: [String:Any] {
        return [
            "id": id,
            "content": content,
            "created": created,
            "senderID": senderID,
            "senderName": senderName]
    }
} //End of struct

extension Message {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let content = dictionary["content"] as? String,
              let created = dictionary["created"] as? Timestamp,
              let senderID = dictionary["senderID"] as? String,
              let senderName = dictionary["senderName"] as? String
        else { return nil }

        self.init(id: id, content: content, created: created, senderID: senderID, senderName: senderName)
    }
} // End of Extension

// Let MessageKit know what type of chat we are implementing (text-based)
extension Message: MessageType {
    // SenderType helps MessageKit understand who sent message.  Helps identify which side of screen to display message(sending on left, receiving on right)
    var sender: SenderType {
        return chatUser(senderId: senderID, displayName: senderName)
    }
    // Unique ID to differentiate messages from eachother
    var messageId: String {
        return id
    }
    // Helps display messages in chronological order
    var sentDate: Date {
        return created.dateValue()
    }
    // What type of message is being sent
    var kind: MessageKind {
        return .text(content)
    }
} // End of Extension
