//
//  ArticleTagPivot.swift
//
//
//  Created by Imen Ksouri on 11/12/2023.
//

import Foundation
import Fluent

final class ArticleTagPivot: Model {
    static let schema = ArticleTagPivot.schemaName

    @ID(key: .id)
    var id: UUID?

    @Parent(key: ArticleTagPivot.articleID)
    var article: Article

    @Parent(key: ArticleTagPivot.tagID)
    var tag: Tag

    init() {}

    init(
        id: UUID? = nil,
        articleID: Article.IDValue,
        tagID: Tag.IDValue
    ) throws {
        self.id = id
        self.$article.id = articleID
        self.$tag.id = tagID
    }
}

extension ArticleTagPivot {
    static let schemaName = "article_tag_pivot"
    static let id = FieldKey(stringLiteral: "id")
    static let articleID = FieldKey(stringLiteral: "article_ID")
    static let tagID = FieldKey(stringLiteral: "tag_ID")
}
