//
//  CreateAcronymCategoryPivot.swift
//
//
//  Created by Imen Ksouri on 11/12/2023.
//

import Foundation
import Fluent

struct CreateAcronymCategoryPivot: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(AcronymCategoryPivot.schema)
      .id()
      .field(AcronymCategoryPivot.acronymID, .uuid, .required,
        .references(Acronym.schema, Acronym.id, onDelete: .cascade))
      .field(AcronymCategoryPivot.categoryID, .uuid, .required,
        .references(Category.schema, Category.id, onDelete: .cascade))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(AcronymCategoryPivot.schema).delete()
  }
}
