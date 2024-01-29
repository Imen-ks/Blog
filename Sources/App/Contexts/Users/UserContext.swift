//
//  UserContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct UserContext: Encodable {
    let title: String
    let user: User.Public
    let articles: [Article]
    let userLoggedIn: Bool
    let userIsAuthor: Bool
}
