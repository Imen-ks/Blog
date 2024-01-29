//
//  GetArticleTagsMiddleware.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct GetArticleTagsMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder)
    -> EventLoopFuture<Response> {
        let articleId = request.parameters.get(WebsitePath.articleId.rawValue) ?? ""
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)/\(ApiPath.tags.rawValue)")
        return request.client.get(uri) { _ in }
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    throw Abort(.notFound)
                }
                let articleContext = try request.content.decode(ArticleContext.self)
                let tags = try response.content.decode([Tag].self)
                let updatedArticleContext = ArticleContext(
                    title: articleContext.title,
                    article: articleContext.article,
                    user: articleContext.user,
                    tags: tags,
                    comments: [])
                return try request.content.encode(updatedArticleContext)
            }.flatMap { _ in
                return next.respond(to: request)
            }
    }
}
