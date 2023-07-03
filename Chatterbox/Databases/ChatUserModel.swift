//
//  ChatUserModel.swift
//  Chatterbox
//
//  Created by Александра Кострова on 29.06.2023.
//

import Foundation

struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        //zuzuzuz1995-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
