//
//  Acronym.swift
//
//
//  Created by Imen Ksouri on 08/12/2023.
//

import Foundation
import Vapor
import Fluent

final class Acronym: Model {
    static let schema = Acronym.schemaName
  
  @ID(key: .id)
  var id: UUID?

  @Field(key: Acronym.short)
  var short: String
  
  @Field(key: Acronym.long)
  var long: String
    
  @OptionalField(key: Acronym.picture)
  var picture: String?

  @Parent(key: Acronym.userID)
  var user: User

  @Siblings(
    through: AcronymCategoryPivot.self,
    from: \.$acronym,
    to: \.$category)
  var categories: [Category]

  @Children(for: \.$acronym)
  var comments: [Comment]

  @Timestamp(key: Acronym.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: Acronym.updatedAt, on: .update)
  var updatedAt: Date?

  init() {}
  
  init(
    id: UUID? = nil,
    short: String,
    long: String,
    picture: String? = nil,
    userID: User.IDValue
  ) {
    self.id = id
    self.short = short
    self.long = long
    self.picture = picture
    self.$user.id = userID
  }
}

extension Acronym: Content {}

extension Acronym {
    static let schemaName = "acronyms"
    static let id = FieldKey(stringLiteral: "id")
    static let short = FieldKey(stringLiteral: "short")
    static let long = FieldKey(stringLiteral: "long")
    static let picture = FieldKey(stringLiteral: "picture")
    static let userID = FieldKey(stringLiteral: "userID")
    static let createdAt = FieldKey(stringLiteral: "created_at")
    static let updatedAt = FieldKey(stringLiteral: "updated_at")
}
