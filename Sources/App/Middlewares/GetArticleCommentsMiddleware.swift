//
//  GetArticleCommentsMiddleware.swift
//
//
//  Created by Imen Ksouri on 18/01/2024.
//

import Foundation
import Vapor

struct GetArticleCommentsMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) 
    -> EventLoopFuture<Response> {
        let articleId = request.parameters.get(WebsitePath.articleId.rawValue) ?? ""
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)/\(ApiPath.comments.rawValue)")
        return request.client.get(uri) { _ in }
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    throw Abort(.notFound)
                }
                let articleContext = try request.content.decode(ArticleContext.self)
                let comments = try response.content.decode([CommentWithAuthor].self)
                let userLoggedIn = request.auth.has(User.self)
                let authUser = request.auth.get(User.self)
                let userIsAuthor = authUser?.id == articleContext.user?.id
                let updatedArticleContext = ArticleContext(
                    title: articleContext.title,
                    article: articleContext.article,
                    user: articleContext.user,
                    tags: articleContext.tags,
                    comments: comments,
                    userLoggedIn: userLoggedIn,
                    userIsAuthor: userIsAuthor)
                return try request.content.encode(updatedArticleContext)
            }.flatMap { _ in
                return next.respond(to: request)
            }
    }
}
