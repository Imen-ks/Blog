//
//  EditAcronymContext.swift
//
//
//  Created by Imen Ksouri on 10/12/2024.
//

import Foundation
import Vapor

struct EditAcronymContext: Encodable {
  let title = WebsiteView.editAcronym.title
  let userLoggedIn: Bool
  let acronym: Acronym
  let editing = true
  let categories: [Category]
  let message: String?

  init(
    userLoggedIn: Bool,
    acronym: Acronym,
    categories: [Category],
    message: String? = nil) {
    self.userLoggedIn = userLoggedIn
    self.acronym = acronym
    self.categories = categories
    self.message = message
  }
}
//
//struct CreateAcronymFormData: Content, Validatable {
//  let short: String
//  let long: String
//  let categories: [String]
//
//  static func validations(_ validations: inout Vapor.Validations) {
//    validations.add("short", as: String.self, is: .count(10...))
//    validations.add("long", as: String.self, is: .count(150...))
//  }
//}
//
//struct SearchContext: Encodable {
//  let title: String
//  let acronyms: [Acronym]?
//  let userLoggedIn: Bool
//}
//
//struct CreateCommentFormData: Content, Validatable {
//  let comment: String
//
//  static func validations(_ validations: inout Vapor.Validations) {
//    validations.add("comment", as: String.self, is: .count(3...))
//  }
//}
