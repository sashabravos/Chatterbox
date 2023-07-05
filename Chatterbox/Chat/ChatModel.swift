//
//  ChatModel.swift
//  Chatterbox
//
//  Created by Александра Кострова on 27.06.2023.
//

import Foundation
import MessageKit

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}
