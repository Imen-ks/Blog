//
//  User.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content {
  static let schema = User.schemaName

  @ID(key: .id)
  var id: UUID?

  @Field(key: User.firstName)
  var firstName: String
   
  @Field(key: User.lastName)
  var lastName: String
   
  @Field(key: User.username)
  var username: String

  @Field(key: User.password)
  var password: String

  @Field(key: User.email)
  var email: String

  @OptionalField(key: User.profilePicture)
  var profilePicture: String?

  @Children(for: \.$user)
  var articles: [Article]

  @Children(for: \.$author)
  var comments: [Comment]

  @Timestamp(key: User.createdAt, on: .create)
  var createdAt: Date?

  init() {}
    
  init(
    id: UUID? = nil,
    firstName: String,
    lastName: String,
    username: String,
    password: String,
    email: String,
    profilePicture: String? = nil
    ) {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
    self.username = username
    self.password = password
    self.email = email
    self.profilePicture = profilePicture
  }

  final class Public: Content {
    var id: UUID?
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var profilePicture: String?
    var createdAt: Date?

    init(id: UUID?,
         firstName: String,
         lastName: String,
         username: String,
         email: String,
         profilePicture: String?,
         createdAt: Date?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.profilePicture = profilePicture
        self.createdAt = createdAt
    }
  }
}

extension User {
  func convertToPublic() -> User.Public {
    return User.Public(
        id: id,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        profilePicture: profilePicture,
        createdAt: createdAt)
  }
}

extension EventLoopFuture where Value: User {
  func convertToPublic() -> EventLoopFuture<User.Public> {
    return self.map { user in
      return user.convertToPublic()
    }
  }
}

extension Collection where Element: User {
  func convertToPublic() -> [User.Public] {
    return self.map { $0.convertToPublic() }
  }
}

extension EventLoopFuture where Value == Array<User> {
  func convertToPublic() -> EventLoopFuture<[User.Public]> {
    return self.map { $0.convertToPublic() }
  }
}

extension User: ModelAuthenticatable, ModelCredentialsAuthenticatable {
  static let usernameKey = \User.$username
  static let passwordHashKey = \User.$password

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.password)
  }
}

extension User: ModelSessionAuthenticatable {}

extension User {
    static let schemaName = "users"
    static let id = FieldKey(stringLiteral: "id")
    static let firstName = FieldKey(stringLiteral: "firstName")
    static let lastName = FieldKey(stringLiteral: "lastName")
    static let username = FieldKey(stringLiteral: "username")
    static let password = FieldKey(stringLiteral: "password")
    static let email = FieldKey(stringLiteral: "email")
    static let profilePicture = FieldKey(stringLiteral: "profilePicture")
    static let createdAt = FieldKey(stringLiteral: "created_at")
}
