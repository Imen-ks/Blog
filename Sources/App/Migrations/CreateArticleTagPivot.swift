//
//  CreateArticleTagPivot.swift
//
//
//  Created by Imen Ksouri on 11/12/2023.
//

import Foundation
import Fluent

struct CreateArticleTagPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ArticleTagPivot.schema)
            .id()
            .field(ArticleTagPivot.articleID, .uuid, .required,
                   .references(Article.schema, Article.id, onDelete: .cascade))
            .field(ArticleTagPivot.tagID, .uuid, .required,
                   .references(Tag.schema, Tag.id, onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ArticleTagPivot.schema).delete()
    }
}
