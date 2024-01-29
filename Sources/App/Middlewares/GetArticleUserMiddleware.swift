//
//  GetArticleUserMiddleware.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct GetArticleUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) 
    -> EventLoopFuture<Response> {
        let articleId = request.parameters.get(WebsitePath.articleId.rawValue) ?? ""
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)/\(ApiPath.user.rawValue)")
        return request.client.get(uri) { _ in }
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    throw Abort(.notFound)
                }
                let user = try response.content.decode(User.Public.self)
                return try request.content.encode(user)
            }.flatMap { _ in
                return next.respond(to: request)
            }
    }
}
