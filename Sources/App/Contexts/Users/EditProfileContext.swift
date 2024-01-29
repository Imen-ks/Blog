//
//  EditProfileContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct EditProfileContext: Encodable {
    let title: String = WebsiteView.editProfile.title
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

struct EditProfileData: Content, Validatable {
    let firstName: String
    let lastName: String
    let username: String
    let email: String

    public static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("email", as: String.self, is: .email)
    }
}

struct ChangePasswordData: Content, Validatable {
    let password: String

    public static func validations(_ validations: inout Validations) {
        validations.add("password", as: String.self, is: .count(8...))
    }
}
