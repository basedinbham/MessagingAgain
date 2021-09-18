//
//  ChatUser.swift
//  MessagingAgain
//
//  Created by Kyle Warren on 9/17/21.
//

import Foundation
import MessageKit

struct chatUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
} //End of struct
