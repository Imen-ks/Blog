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
        let tagsRoute = routes.grouped(ApiPath.api.component, ApiPath.tags.component)

        tagsRoute.get(use: getAllHandler)
        tagsRoute.get(ApiPath.tagId.component, use: getHandler)
        tagsRoute.get(ApiPath.tagId.component, ApiPath.articles.component, use: getArticlesHandler)
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
