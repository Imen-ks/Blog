//
//  Tag.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Fluent
import Vapor

final class Tag: Model, Content {
    static let schema = Tag.schemaName

    @ID(key: .id)
    var id: UUID?

    @Field(key: Tag.name)
    var name: String

    @Siblings(
        through: ArticleTagPivot.self,
        from: \.$tag,
        to: \.$article)
    var articles: [Article]

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag {
    static func addTag(
        _ name: String,
        to article: Article,
        on req: Request
    ) -> EventLoopFuture<Void> {
        return Tag.query(on: req.db)
            .filter(\.$name == name.lowercased())
            .first()
            .flatMap { foundTag in
                if let existingTag = foundTag {
                    return article.$tags.attach(existingTag, on: req.db)
                } else {
                    let tag = Tag(name: name.lowercased())
                    return tag.save(on: req.db).flatMap {
                        return article.$tags.attach(tag, on: req.db)
                    }
                }
            }
    }

    static func removeTag(
        _ name: String,
        to article: Article,
        on req: Request
    ) -> EventLoopFuture<Void> {
        return Tag.query(on: req.db)
            .filter(\.$name == name.lowercased())
            .all()
            .flatMap { foundTags in
                foundTags.sequencedFlatMapEach(on: req.eventLoop) { tag in
                    return article.$tags.detach(tag, on: req.db)
                }
            }
    }

    static func updateTags(
        _ names: [String],
        for article: Article,
        on req: Request
    ) -> EventLoopFuture<Void> {
        article.$tags.get(on: req.db).flatMap { existingTags in
            let existingStringArray = existingTags.map {
                $0.name
            }
            let existingSet = Set<String>(existingStringArray)
            let newSet = Set<String>(names)
            let tagsToAdd = newSet.subtracting(existingSet)
            let tagsToRemove = existingSet.subtracting(newSet)
            var tagsResults: [EventLoopFuture<Void>] = []
            for newTag in tagsToAdd {
                tagsResults.append(
                    Tag.addTag(newTag, to: article, on: req))
            }
            for tagNameToRemove in tagsToRemove {
                tagsResults.append(
                    Tag.removeTag(tagNameToRemove, to: article, on: req))
            }
            return tagsResults.flatten(on: req.eventLoop).map { $0 }
        }
    }
}

extension Tag {
    static let schemaName = "tags"
    static let id = FieldKey(stringLiteral: "id")
    static let name = FieldKey(stringLiteral: "name")
}
