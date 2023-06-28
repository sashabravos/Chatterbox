//
//  ProfileViewModel.swift
//  Chatterbox
//
//  Created by Александра Кострова on 27.06.2023.
//

import Foundation

enum ProfileViewModelType {
    case changeAvatar, info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
