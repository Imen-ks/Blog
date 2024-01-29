//
//  RegisterContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct RegisterContext: Encodable {
    let title = WebsiteView.register.title
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }
}

struct RegisterData: Content, Validatable {
    let firstName: String
    let lastName: String
    let username: String
    let password: String
    let email: String

    public static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("email", as: String.self, is: .email)
    }
}
