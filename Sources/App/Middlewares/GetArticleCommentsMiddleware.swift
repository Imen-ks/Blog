//
//  GetAcronymCommentsMiddleware.swift
//
//
//  Created by Imen Ksouri on 18/01/2024.
//

import Foundation
import Vapor

struct GetAcronymCommentsMiddleware: Middleware {
  func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    let acronymId = request.parameters.get(WebsitePath.acronymId.rawValue) ?? ""
    return request.client.get("\(ApiEndpoint.acronyms.url)/\(acronymId)/\(ApiPath.comments.rawValue)") { _ in }
      .flatMapThrowing { response in
        guard response.status == .ok else {
          throw Abort(.notFound)
        }
        let acronymContext = try request.content.decode(AcronymContext.self)
        let comments = try response.content.decode([CommentWithAuthor].self)
        let userLoggedIn = request.auth.has(User.self)
        let authUser = request.auth.get(User.self)
        let userIsAuthor = authUser?.id == acronymContext.user?.id
        let updatedAcronymContext = AcronymContext(
            title: acronymContext.title,
            acronym: acronymContext.acronym,
            user: acronymContext.user,
            categories: acronymContext.categories,
            comments: comments,
            userLoggedIn: userLoggedIn,
            userIsAuthor: userIsAuthor)
        return try request.content.encode(updatedAcronymContext)
      }.flatMap { _ in
        return next.respond(to: request)
      }
  }
}
