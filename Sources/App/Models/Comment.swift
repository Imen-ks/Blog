//
//  Comment.swift
//
//
//  Created by Imen Ksouri on 17/01/2024.
//

import Foundation
import Vapor
import Fluent

final class Comment: Model, Content {
    static let schema = Comment.schemaName

    @ID(key: .id)
    var id: UUID?

    @Field(key: Comment.description)
    var description: String

    @Parent(key: Comment.userID)
    var author: User

    @Parent(key: Comment.articleID)
    var article: Article

    @Timestamp(key: Comment.createdAt, on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        description: String,
        userID: User.IDValue,
        articleId: Article.IDValue) {
            self.id = id
            self.description = description
            self.$author.id = userID
            self.$article.id = articleId
        }
}

extension Comment {
    static let schemaName = "comments"
    static let id = FieldKey(stringLiteral: "id")
    static let description = FieldKey(stringLiteral: "description")
    static let userID = FieldKey(stringLiteral: "user_ID")
    static let articleID = FieldKey(stringLiteral: "article_ID")
    static let createdAt = FieldKey(stringLiteral: "created_at")
}
