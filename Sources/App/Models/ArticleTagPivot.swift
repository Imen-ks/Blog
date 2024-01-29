//
//  AcronymCategoryPivot.swift
//
//
//  Created by Imen Ksouri on 11/12/2023.
//

import Foundation
import Fluent

final class AcronymCategoryPivot: Model {
  static let schema = AcronymCategoryPivot.schemaName
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: AcronymCategoryPivot.acronymID)
  var acronym: Acronym
  
  @Parent(key: AcronymCategoryPivot.categoryID)
  var category: Category
  
  init() {}
  
  init(
    id: UUID? = nil,
    acronym: Acronym,
    category: Category
  ) throws {
    self.id = id
    self.$acronym.id = try acronym.requireID()
    self.$category.id = try category.requireID()
  }
}

extension AcronymCategoryPivot {
    static let schemaName = "acronym-category-pivot"
    static let id = FieldKey(stringLiteral: "id")
    static let acronymID = FieldKey(stringLiteral: "acronymID")
    static let categoryID = FieldKey(stringLiteral: "categoryID")
}
