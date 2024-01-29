//
//  Article.swift
//
//
//  Created by Imen Ksouri on 08/12/2023.
//

import Foundation
import Vapor
import Fluent

final class Article: Model {
    static let schema = Article.schemaName

    @ID(key: .id)
    var id: UUID?

    @Field(key: Article.title)
    var title: String

    @Field(key: Article.description)
    var description: String

    @OptionalField(key: Article.picture)
    var picture: String?

    @Parent(key: Article.userID)
    var user: User

    @Siblings(
        through: ArticleTagPivot.self,
        from: \.$article,
        to: \.$tag)
    var tags: [Tag]

    @Children(for: \.$article)
    var comments: [Comment]

    @Timestamp(key: Article.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: Article.updatedAt, on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        title: String,
        description: String,
        picture: String? = nil,
        userID: User.IDValue
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.picture = picture
        self.$user.id = userID
    }
}

extension Article: Content {}

extension Article {
    static let schemaName = "articles"
    static let id = FieldKey(stringLiteral: "id")
    static let title = FieldKey(stringLiteral: "title")
    static let description = FieldKey(stringLiteral: "description")
    static let picture = FieldKey(stringLiteral: "picture")
    static let userID = FieldKey(stringLiteral: "user_ID")
    static let createdAt = FieldKey(stringLiteral: "created_at")
    static let updatedAt = FieldKey(stringLiteral: "updated_at")
}
