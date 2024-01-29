//
//  ProfileContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct ProfileContext: Encodable {
    let title: String = WebsiteView.profile.title
    let user: User.Public
    let userLoggedIn: Bool
    let message: String?

    init(
        user: User.Public,
        userLoggedIn: Bool,
        message: String? = nil) {
            self.user = user
            self.userLoggedIn = userLoggedIn
            self.message = message
        }
}
