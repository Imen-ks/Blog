//
//  UsersController.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Vapor

struct UsersController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoute = routes.grouped(ApiPath.api.component, ApiPath.users.component)

    let basicAuthMiddleware = User.authenticator()
    let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)

    basicAuthGroup.post(ApiPath.login.component, use: loginHandler)
    usersRoute.post(use: createHandler)
    usersRoute.get(use: getAllHandler)
    usersRoute.get(ApiPath.userId.component, use: getHandler)
    tokenAuthGroup.put(ApiPath.userId.component, use: updateHandler)
    usersRoute.get(ApiPath.userId.component, ApiPath.articles.component, use: userArticlesHandler)
    usersRoute.get(ApiPath.userId.component, ApiPath.comments.component, use: getCommentsHandler)
  }

  func loginHandler(_ req: Request) throws
    -> EventLoopFuture<Token> {
    let user = try req.auth.require(User.self)
    let token = try Token.generate(for: user)
    return token.save(on: req.db).map { token }
  }

  func createHandler(_ req: Request)
    throws -> EventLoopFuture<User> {
    let user = try req.content.decode(User.self)
    user.password = try Bcrypt.hash(user.password)
    return user.save(on: req.db).map { user }
  }

  func getAllHandler(_ req: Request)
    -> EventLoopFuture<[User.Public]> {
    User.query(on: req.db).all().convertToPublic()
  }

  func getHandler(_ req: Request)
    -> EventLoopFuture<User.Public> {
    User.find(req.parameters.get(ApiPath.userId.rawValue), on: req.db)
        .unwrap(or: Abort(.notFound))
        .convertToPublic()
  }

  func updateHandler(_ req: Request) throws
      -> EventLoopFuture<User> {
    let updateData = try req.content.decode(UpdateUserData.self)
    let user = try req.auth.require(User.self)
    let userID = try user.requireID()
    let formattedPassword = updateData.password != nil ? try Bcrypt.hash(updateData.password!) : user.password
    return User.find(req.parameters.get(ApiPath.userId.rawValue),
        on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { user in
        user.firstName = updateData.firstName != nil ? updateData.firstName! : user.firstName
        user.lastName = updateData.lastName != nil ? updateData.lastName! : user.lastName
        user.username = updateData.username != nil ? updateData.username! : user.username
        user.password = formattedPassword
        user.email = updateData.email != nil ? updateData.email! : user.email
        user.profilePicture = updateData.profilePicture != nil ? updateData.profilePicture! : user.profilePicture
        user.id = userID
        return user.save(on: req.db).map {
            return user
        }
    }
  }

  func userArticlesHandler(_ req: Request)
    -> EventLoopFuture<[Article]> {
    User.find(req.parameters.get(ApiPath.userId.rawValue), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { user in
            user.$articles.query(on: req.db)
                .sort(\.$updatedAt, .descending)
                .all()
    }
  }

  func getCommentsHandler(_ req: Request)
    -> EventLoopFuture<[CommentWithAcronym]> {
    return Comment.query(on: req.db)
        .with(\.$article) { articles in }
        .all()
        .flatMapThrowing { comments in
            return comments
                .filter {
                    $0.$author.id.uuidString == req.parameters.get(ApiPath.userId.rawValue)
                }
                .sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
                .map {
                    CommentWithAcronym(
                        id: $0.id,
                        description: $0.description,
                        createdAt: $0.createdAt,
                        acronym: $0.article)
                }
        }
  }
}

struct UpdateUserData: Content {
  let firstName: String?
  let lastName: String?
  let username: String?
  let password: String?
  let email: String?
  let profilePicture: String?

  init(
    firstName: String? = nil,
    lastName: String? = nil,
    username: String? = nil,
    password: String? = nil,
    email: String? = nil,
    profilePicture: String?) {
    self.firstName = firstName
    self.lastName = lastName
    self.username = username
    self.password = password
    self.email = email
    self.profilePicture = profilePicture
  }
}

struct CommentWithAcronym: Content {
  let id: UUID?
  let description: String
  let createdAt: Date?
  let acronym: Article
}
