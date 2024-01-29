//
//  CreateComment.swift
//
//
//  Created by Imen Ksouri on 17/01/2024.
//

import Foundation
import Fluent

struct CreateComment: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Comment.schema)
            .id()
            .field(Comment.description, .string, .required)
            .field(Comment.userID, .uuid, .required,
                   .references(User.schema, User.id, onDelete: .cascade))
            .field(Comment.articleID, .uuid, .required,
                   .references(Article.schema, Article.id, onDelete: .cascade))
            .field(Comment.createdAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Comment.schema).delete()
    }
}
