//
//  CreateArticleContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct CreateArticleContext: Encodable {
    let title = WebsiteView.createArticle.title
    let userLoggedIn: Bool
    let message: String?

    init(userLoggedIn: Bool, message: String? = nil) {
        self.userLoggedIn = userLoggedIn
        self.message = message
    }
}

struct CreateArticleFormData: Content, Validatable {
    let title: String
    let description: String
    let tags: [String]

    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("title", as: String.self, is: .count(10...))
        validations.add("description", as: String.self, is: .count(150...))
    }
}
