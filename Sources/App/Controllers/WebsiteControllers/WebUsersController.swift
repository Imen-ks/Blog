//
//  WebUsersController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebUsersController: RouteCollection {
  let imageFolder = WorkingDirectoryFolder.profilePictures

  func boot(routes: RoutesBuilder) throws {
    let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
    let protectedRoutes = authSessionsRoutes
          .grouped(Token.generateToken(), User.redirectMiddleware(path: WebsiteEndpoint.login.url))

    authSessionsRoutes.get(WebsitePath.users.component, WebsitePath.userId.component, use: userHandler)
    authSessionsRoutes.get(WebsitePath.users.component, use: allUsersHandler)
    authSessionsRoutes.get(WebsitePath.profile.component, use: profileHandler)
    protectedRoutes.get(WebsitePath.users.component, WebsitePath.userId.component, WebsitePath.addProfilePicture.component, use: addProfilePictureHandler)
    protectedRoutes.on(
      .POST,
      WebsitePath.users.component,
      WebsitePath.userId.component,
      WebsitePath.addProfilePicture.component,
      body: .collect(maxSize: "10mb"),
      use: addProfilePicturePostHandler)
      protectedRoutes.get(WebsitePath.profile.component, WebsitePath.edit.component, use: editProfileHandler)
      protectedRoutes.post(WebsitePath.profile.component, WebsitePath.edit.component, use: editProfilePostHandler)
      protectedRoutes.post(WebsitePath.profile.component, WebsitePath.changePassword.component, use: changePasswordHandler)
      protectedRoutes.get(WebsitePath.users.component, WebsitePath.userId.component, WebsitePath.comments.component, use: userCommentsHandler)
  }

  func userHandler(_ req: Request) throws -> EventLoopFuture<View> {
    let userId = req.parameters.get(WebsitePath.userId.rawValue) ?? ""
    let userLoggedIn = req.auth.has(User.self)
    let user = req.auth.get(User.self)
    let userIsAuthor = user?.id?.uuidString == userId
    return req.client.get("\(ApiEndpoint.users.url)/\(userId)") { _ in }
      .flatMapThrowing { clientResponse -> User.Public in
        guard clientResponse.status == .ok else {
            throw Abort(.notFound)
        }
        return try clientResponse.content.decode(User.Public.self)
      }
      .flatMap { user in
        req.client.get("\(ApiEndpoint.users.url)/\(userId)/\(ApiEndpoint.acronyms.rawValue)") { _ in }
          .flatMapThrowing { clientResponse -> [Acronym] in
              guard clientResponse.status == .ok else {
                  throw Abort(.notFound)
              }
              return try clientResponse.content.decode([Acronym].self)
          }
          .flatMap { acronyms in
              let context = UserContext(
                title: userIsAuthor ? "My Articles" : "\(user.username) articles",
                user: user,
                acronyms: acronyms,
                userLoggedIn: userLoggedIn,
                userIsAuthor: userIsAuthor)
              return req.view.render(WebsiteView.userAcronyms.leafRenderer, context)
          }
      }
  }

  func allUsersHandler(_ req: Request) -> EventLoopFuture<View> {
    let userLoggedIn = req.auth.has(User.self)
    return req.client.get(URI(string: ApiEndpoint.users.url)) { _ in }
      .flatMapThrowing { clientResponse -> [User.Public] in
        guard clientResponse.status == .ok else {
          throw Abort(.notFound)
        }
        return try clientResponse.content.decode([User.Public].self)
      }
      .flatMap { users in
        let context = AllUsersContext(users: users, userLoggedIn: userLoggedIn)
        return req.view.render(WebsiteView.allUsers.leafRenderer, context)
      }
  }

  func profileHandler(_ req: Request) throws -> EventLoopFuture<View> {
    let userLoggedIn = req.auth.has(User.self)
    let user = req.auth.get(User.self)
    let userId = try user?.requireID().uuidString ?? ""
    return req.client.get("\(ApiEndpoint.users.url)/\(userId)") { _ in }
      .flatMapThrowing { clientResponse -> User.Public in
        guard clientResponse.status == .ok else {
            throw Abort(.notFound)
        }
        return try clientResponse.content.decode(User.Public.self)
      }
      .flatMap { user in
          let context: ProfileContext
          if let message = req.query[String.self, at: "message"] {
            context = ProfileContext(
                user: user,
                userLoggedIn: userLoggedIn,
                message: message)
          } else {
            context = ProfileContext(
                user: user,
                userLoggedIn: userLoggedIn)
          }
          return req.view.render(WebsiteView.profile.leafRenderer, context)
      }
  }

  func addProfilePictureHandler(_ req: Request) -> EventLoopFuture<View> {
    let userLoggedIn = req.auth.has(User.self)
    let userId = req.parameters.get(WebsitePath.userId.rawValue) ?? ""
    return req.client.get("\(ApiEndpoint.users.url)/\(userId)") { _ in }
      .flatMapThrowing { clientResponse -> User.Public in
        guard clientResponse.status == .ok else {
          throw Abort(.notFound)
        }
        return try clientResponse.content.decode(User.Public.self)
      }
      .flatMap { user in
        let context = ImageUploadContext(
            title: WebsiteView.addProfilePicture.title,
            pictureType: PictureType.profile.rawValue,
            reference: user.username,
            currentImage: user.profilePicture,
            userLoggedIn: userLoggedIn,
            acronymId: nil)
        return req.view.render(WebsiteView.addProfilePicture.leafRenderer, context)
      }
  }

  func addProfilePicturePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
    let data = try req.content.decode(ImageUploadData.self)
    let userId = req.parameters.get(WebsitePath.userId.rawValue) ?? ""
    return req.client.get("\(ApiEndpoint.users.url)/\(userId)") { _ in }
      .flatMapThrowing { clientResponse -> User.Public in
        guard clientResponse.status == .ok else {
            throw Abort(.notFound)
        }
        return try clientResponse.content.decode(User.Public.self)
      }
      .flatMap { user in
          let name = "\(userId)-\(UUID()).jpg"
          let path = req.application.directory.workingDirectory +
          imageFolder + name
          return req.fileio
            .writeFile(.init(data: data.picture), at: path)
            .flatMap {
              return req.client.put("\(ApiEndpoint.users.url)/\(userId)", headers: req.headers) { clientRequest in
                  let data = UpdateUserData(profilePicture: name)
                  try clientRequest.content.encode(data)
              }
              .flatMap { _ in
                  let redirect = req.redirect(to: WebsiteEndpoint.profile.url)
                  return redirect.encodeResponse(for: req)
              }
            }
      }
  }

  func editProfileHandler(_ req: Request) throws -> EventLoopFuture<View> {
    let userLoggedIn = req.auth.has(User.self)
    let user = req.auth.get(User.self)
    let userId = try user?.requireID().uuidString ?? ""
    return req.client.get("\(ApiEndpoint.users.url)/\(userId)") { _ in }
      .flatMapThrowing { clientResponse -> User.Public in
        guard clientResponse.status == .ok else {
            throw Abort(.notFound)
        }
        return try clientResponse.content.decode(User.Public.self)
      }
      .flatMap { user in
          let context: EditProfileContext
          if let message = req.query[String.self, at: "message"] {
            context = EditProfileContext(
                user: user,
                userLoggedIn: userLoggedIn,
                message: message)
          } else {
            context = EditProfileContext(
                user: user,
                userLoggedIn: userLoggedIn)
          }
          return req.view.render(WebsiteView.editProfile.leafRenderer, context)
      }
  }

  func editProfilePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
    do {
      try EditProfileData.validate(content: req)
    } catch let error as ValidationsError {
      let message = error.description.addingPercentEncoding(
        withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
      let redirect = req.redirect(to: "\(WebsiteEndpoint.profile.url)/\(WebsitePath.edit.component)?message=\(message)")
      return req.eventLoop.future(redirect)
    }
    let updateData = try req.content.decode(EditProfileData.self)
    let user = req.auth.get(User.self)
    let userId = try user?.requireID().uuidString ?? ""
    return req.client.put(
      "\(ApiEndpoint.users.url)/\(userId)",
      headers: req.headers) { clientRequest in
      try clientRequest.content.encode(updateData)
    }
    .flatMapThrowing { clientResponse in
      guard clientResponse.status == .ok else {
          if clientResponse.status == .unauthorized {
              throw Abort(.unauthorized)
          } else {
              throw Abort(.internalServerError)
          }
      }
      return req.redirect(to: WebsiteEndpoint.profile.url)
    }
  }

  func changePasswordHandler(_ req: Request) throws -> EventLoopFuture<Response> {
    do {
      try ChangePasswordData.validate(content: req)
    } catch let error as ValidationsError {
      let message = error.description.addingPercentEncoding(
        withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
      let redirect = req.redirect(to: "\(WebsiteEndpoint.profile.url)/?message=\(message)")
      return req.eventLoop.future(redirect)
    }
    let updateData = try req.content.decode(ChangePasswordData.self)
    let user = req.auth.get(User.self)
    let userId = try user?.requireID().uuidString ?? ""
    return req.client.put(
      "\(ApiEndpoint.users.url)/\(userId)",
      headers: req.headers) { clientRequest in
      try clientRequest.content.encode(updateData)
    }
    .flatMapThrowing { clientResponse in
      guard clientResponse.status == .ok else {
          if clientResponse.status == .unauthorized {
              throw Abort(.unauthorized)
          } else {
              throw Abort(.internalServerError)
          }
      }
      req.auth.logout(User.self)
      return req.redirect(to: WebsiteEndpoint.login.url)
    }
  }

  func userCommentsHandler(_ req: Request) throws -> EventLoopFuture<View> {
    let userLoggedIn = req.auth.has(User.self)
    let user = req.auth.get(User.self)
    let userId = try user?.requireID().uuidString ?? ""
    return req.client.get(
      "\(ApiEndpoint.users.url)/\(userId)/\(ApiPath.comments.rawValue)",
      headers: req.headers) { clientRequest in }
    .flatMapThrowing { clientResponse -> [CommentWithAcronym] in
        guard clientResponse.status == .ok else {
          throw Abort(.notFound)
        }
        return try clientResponse.content.decode([CommentWithAcronym].self)
    }
    .flatMap { comments in
        let context = UserCommentsContext(
            user: user?.convertToPublic(),
            comments: comments,
            userLoggedIn: userLoggedIn)
        return req.view.render(WebsiteView.userComments.leafRenderer, context)
    }
  }
}

struct UserContext: Encodable {
  let title: String
  let user: User.Public
  let acronyms: [Acronym]
  let userLoggedIn: Bool
  let userIsAuthor: Bool
}

struct AllUsersContext: Encodable {
  let title = WebsiteView.allUsers.title
  let users: [User.Public]
  let userLoggedIn: Bool
}

enum PictureType: String {
    case profile
    case acronym
}

struct ImageUploadContext: Encodable {
  let title: String
  let pictureType: String
  let reference: String
  let currentImage: String?
  let userLoggedIn: Bool
  let acronymId: String?
}

struct ImageUploadData: Content {
  let picture: Data
}

struct ProfileContext: Encodable {
  let title: String = WebsiteView.profile.title
  let user: User.Public
  let userLoggedIn: Bool
  let message: String?

  init(
    user: User.Public,
    userLoggedIn: Bool,
    message: String? = nil) {
    self.user = user
    self.userLoggedIn = userLoggedIn
    self.message = message
  }
}

struct EditProfileContext: Encodable {
  let title: String = WebsiteView.editProfile.title
  let user: User.Public
  let userLoggedIn: Bool
  let message: String?

  init(
    user: User.Public,
    userLoggedIn: Bool,
    message: String? = nil) {
    self.user = user
    self.userLoggedIn = userLoggedIn
    self.message = message
  }
}

struct EditProfileData: Content, Validatable {
  let firstName: String
  let lastName: String
  let username: String
  let email: String
    
  public static func validations(_ validations: inout Validations) {
    validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
    validations.add("email", as: String.self, is: .email)
  }
}

struct ChangePasswordData: Content, Validatable {
  let password: String

  public static func validations(_ validations: inout Validations) {
    validations.add("password", as: String.self, is: .count(8...))
  }
}

struct UserCommentsContext: Encodable {
  let title: String = WebsiteView.userComments.title
  let user: User.Public?
  let comments: [CommentWithAcronym]
  let userLoggedIn: Bool
}
