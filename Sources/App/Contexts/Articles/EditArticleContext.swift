//
//  EditArticleContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct EditArticleContext: Encodable {
    let title = WebsiteView.editArticle.title
    let userLoggedIn: Bool
    let article: Article
    let editing = true
    let tags: [Tag]
    let message: String?

    init(
        userLoggedIn: Bool,
        article: Article,
        tags: [Tag],
        message: String? = nil) {
            self.userLoggedIn = userLoggedIn
            self.article = article
            self.tags = tags
            self.message = message
        }
}
