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
    
    static func addTags(
        _ names: [String],
        to article: Article,
        on req: Request
    ) -> EventLoopFuture<[Tag]> {
        var tagResults: [EventLoopFuture<Void>] = []
        for name in names {
            tagResults.append(Tag.addTag(name, to: article, on: req))
        }
        return tagResults.flatten(on: req.eventLoop).flatMap { _ in
            return article.$tags.get(on: req.db)
        }
    }

    static func updateTags(
        _ names: [String],
        for article: Article,
        on req: Request
    ) -> EventLoopFuture<[Category]> {
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
                tagsResults.append(Tag.addTag(newTag, to: article, on: req))
            }
            for categoryNameToRemove in categoriesToRemove {
                let categoryToRemove = existingCategories.first {
                    $0.name == categoryNameToRemove
                }
                if let category = categoryToRemove {
                    categoryResults.append(
                        acronym.$categories.detach(category, on: req.db))
                }
            }
            return categoryResults.flatten(on: req.eventLoop).flatMap { _ in
                return acronym.$categories.get(on: req.db)
            }
        }
    }
}

extension Tag {
    static let schemaName = "categories"
    static let id = FieldKey(stringLiteral: "id")
    static let name = FieldKey(stringLiteral: "name")
}
