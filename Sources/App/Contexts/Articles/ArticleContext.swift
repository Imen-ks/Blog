//
//  File.swift
//  
//
//  Created by Imen Ksouri on 10/12/2024.
//

import Foundation
import Vapor

//struct IndexContext: Encodable {
//  let title = WebsiteView.index.title
//  let acronyms: [Acronym]
//  let userLoggedIn: Bool
//  let showCookieMessage: Bool
//}

struct ArticleContext: Content {
  let title: String
  let article: Article
  let user: User.Public?
  let tags: [Tag]
  let comments: [CommentWithAuthor]
  let userLoggedIn: Bool
  let userIsAuthor: Bool

  init(title: String,
       article: Article,
       user: User.Public?,
       tags: [Tag],
       comments: [CommentWithAuthor],
       userLoggedIn: Bool = false,
       userIsAuthor: Bool = false) {
    self.title = title
    self.article = article
    self.user = user
    self.tags = tags
    self.comments = comments
    self.userLoggedIn = userLoggedIn
    self.userIsAuthor = userIsAuthor
  }
}

//struct CreateAcronymContext: Encodable {
//  let title = WebsiteView.createAcronym.title
//  let userLoggedIn: Bool
//  let message: String?
//
//  init(userLoggedIn: Bool, message: String? = nil) {
//    self.userLoggedIn = userLoggedIn
//    self.message = message
//  }
//}
//
//struct EditAcronymContext: Encodable {
//  let title = WebsiteView.editAcronym.title
//  let userLoggedIn: Bool
//  let acronym: Acronym
//  let editing = true
//  let categories: [Category]
//  let message: String?
//
//  init(
//    userLoggedIn: Bool,
//    acronym: Acronym,
//    categories: [Category],
//    message: String? = nil) {
//    self.userLoggedIn = userLoggedIn
//    self.acronym = acronym
//    self.categories = categories
//    self.message = message
//  }
//}
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
