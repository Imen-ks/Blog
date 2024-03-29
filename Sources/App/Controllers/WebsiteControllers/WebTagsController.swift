//
//  WebTagsController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebTagsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // PATH COMPONENTS
        let tags = WebsitePath.tags.component
        let tagId = WebsitePath.tagId.component

        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        
        authSessionsRoutes.get(tags, use: allTagsHandler)
        authSessionsRoutes.get(tags, tagId, use: tagHandler)
    }

    func allTagsHandler(_ req: Request) -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        let uri = URI(string: ApiEndpoint.tags.url)
        return req.client.get(uri) { _ in }
            .flatMapThrowing { clientResponse -> [Tag] in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode([Tag].self)
            }
            .flatMap { tags in
                let context = AllTagsContext(userLoggedIn: userLoggedIn, tags: tags)
                return req.view.render(WebsiteView.allTags.leafRenderer, context)
            }
    }

    func tagHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        guard let tagId = req.parameters.get(WebsitePath.tagId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.tags.url)/\(tagId)")
        return req.client.get(uri) { _ in }
            .flatMapThrowing { clientResponse -> Tag in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode(Tag.self)
            }
            .flatMap { tag in
                let getTagArticlesUri = URI(string: "\(ApiEndpoint.tags.url)/\(tagId)/\(ApiEndpoint.articles.rawValue)")
                return req.client.get(getTagArticlesUri) { _ in }
                    .flatMapThrowing { clientResponse -> [Article] in
                        guard clientResponse.status == .ok else {
                            throw Abort(.notFound)
                        }
                        return try clientResponse.content.decode([Article].self)
                    }
                    .flatMap { articles in
                        let context = TagContext(
                            title: tag.name,
                            userLoggedIn: userLoggedIn,
                            tag: tag,
                            articles: articles)
                        return req.view.render(WebsiteView.tag.leafRenderer, context)
                    }
            }
    }
}
