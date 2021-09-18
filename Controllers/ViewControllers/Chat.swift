//
//  Chat.swift
//  MessagingAgain
//
//  Created by Kyle Warren on 9/17/21.
//

import Foundation

struct Chat {
    
    var users: [String]
    var dictionary: [String: Any] {
        return ["users": users]
    }
} //End of struct

extension Chat {
    init?(dictionary: [String:Any]) {
        guard let chatUsers = dictionary["users"] as? [String] else { return nil }
        // Initialize class with users
        self.init(users: chatUsers)
    }
} // End of Extension
