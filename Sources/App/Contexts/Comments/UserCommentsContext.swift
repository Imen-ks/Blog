//
//  UserCommentsContext.swift
//
//
//  Created by Imen Ksouri on 18/01/2024.
//

import Foundation
import Vapor

struct UserCommentsContext: Encodable {
    let title: String = WebsiteView.userComments.title
    let user: User.Public?
    let comments: [CommentWithArticle]
    let userLoggedIn: Bool
}

struct CreateCommentFormData: Content, Validatable {
    let comment: String
    
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("comment", as: String.self, is: .count(3...))
    }
}
