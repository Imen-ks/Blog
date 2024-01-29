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

  @Parent(key: Comment.acronymID)
  var article: Article

  @Timestamp(key: Comment.createdAt, on: .create)
  var createdAt: Date?

  init() {}

    init(
        id: UUID? = nil,
        description: String,
        userID: User.IDValue,
        acronymId: Acronym.IDValue) {
    self.id = id
    self.description = description
    self.$author.id = userID
    self.$acronym.id = acronymId
  }
}

extension Comment {
    static let schemaName = "comments"
    static let id = FieldKey(stringLiteral: "id")
    static let description = FieldKey(stringLiteral: "description")
    static let userID = FieldKey(stringLiteral: "userID")
    static let acronymID = FieldKey(stringLiteral: "acronymID")
    static let createdAt = FieldKey(stringLiteral: "created_at")
}
