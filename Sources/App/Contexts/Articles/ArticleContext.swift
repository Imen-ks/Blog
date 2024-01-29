//
//  ArticleContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct ArticleContext: Content {
    let title: String
    let article: Article
    let user: User.Public?
    let tags: [Tag]
    let comments: [CommentWithAuthor]
    let userLoggedIn: Bool
    let userIsAuthor: Bool

    init(title: String,
         article: Article,
         user: User.Public?,
         tags: [Tag],
         comments: [CommentWithAuthor],
         userLoggedIn: Bool = false,
         userIsAuthor: Bool = false) {
        self.title = title
        self.article = article
        self.user = user
        self.tags = tags
        self.comments = comments
        self.userLoggedIn = userLoggedIn
        self.userIsAuthor = userIsAuthor
    }
}
