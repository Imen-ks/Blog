//
//  File.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct LoginContext: Encodable {
    let title = WebsiteView.login.title
    let loginError: Bool

    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct Credentials: Content {
    let username: String
    let password: String
}
