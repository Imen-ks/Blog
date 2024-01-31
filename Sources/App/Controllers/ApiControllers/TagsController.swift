//
//  TagsController.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Vapor

struct TagsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // PATH COMPONENTS
        let api = ApiPath.api.component
        let tags = ApiPath.tags.component
        let tagId = ApiPath.tagId.component
        let articles = ApiPath.articles.component

        let tagsRoute = routes.grouped(api, tags)

        tagsRoute.get(use: getAllHandler)
        tagsRoute.get(tagId, use: getHandler)
        tagsRoute.get(tagId, articles, use: getArticlesHandler)
    }

    func getAllHandler(_ req: Request)
    -> EventLoopFuture<[Tag]> {
        Tag.query(on: req.db).sort(\.$name, .ascending).all()
    }

    func getHandler(_ req: Request)
    -> EventLoopFuture<Tag> {
        Tag.find(req.parameters.get(ApiPath.tagId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func getArticlesHandler(_ req: Request)
    -> EventLoopFuture<[Article]> {
        Tag.find(req.parameters.get(ApiPath.tagId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { tag in
                tag.$articles.query(on: req.db)
                    .sort(\.$updatedAt, .descending)
                    .all()
            }
    }
}
