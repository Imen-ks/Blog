//
//  CreateArticle.swift
//
//
//  Created by Imen Ksouri on 08/12/2023.
//

import Foundation
import Fluent

struct CreateArticle: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Article.schema)
            .id()
            .field(Article.title, .string, .required)
            .field(Article.description, .string, .required)
            .field(Article.picture, .string)
            .field(Article.userID, .uuid, .required, .references(User.schema, User.id))
            .field(Article.createdAt, .datetime)
            .field(Article.updatedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Article.schema).delete()
    }
}
