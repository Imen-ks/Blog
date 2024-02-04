//
//  ArticlesController.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Vapor

struct ArticlesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // PATH COMPONENTS
        let api = ApiPath.api.component
        let articles = ApiPath.articles.component
        let articleId = ApiPath.articleId.component
        let tags = ApiPath.tags.component
        let comments = ApiPath.comments.component
        let search = ApiPath.search.component
        let user = ApiPath.user.component

        let articlesRoutes = routes.grouped(api, articles)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = articlesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

        tokenAuthGroup.post(use: createHandler)
        articlesRoutes.get(use: getAllHandler)
        articlesRoutes.get(articleId, use: getHandler)
        tokenAuthGroup.put(articleId, use: updateHandler)
        tokenAuthGroup.delete(articleId, use: deleteHandler)
        articlesRoutes.get(search, use: searchHandler)
        articlesRoutes.get(articleId, user, use: getUserHandler)
        articlesRoutes.get(articleId, tags, use: getTagsHandler)
        tokenAuthGroup.post(articleId, tags, use: updateTagsHandler)
        articlesRoutes.get(articleId, comments, use: getCommentsHandler)
        tokenAuthGroup.post(articleId, comments, use: createCommentHandler)
    }

    func createHandler(_ req: Request) throws
    -> EventLoopFuture<Article> {
        let data = try req.content.decode(CreateArticleData.self)
        let user = try req.auth.require(User.self)
        let article = Article(
            title: data.title,
            description: data.description,
            picture: data.picture,
            userID: try user.requireID())
        return article.save(on: req.db).map { article }

    }

    func getAllHandler(_ req: Request)
    -> EventLoopFuture<[Article]> {
        Article.query(on: req.db).sort(\.$updatedAt, .descending).all()
    }

    func getHandler(_ req: Request)
    -> EventLoopFuture<Article> {
        Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func updateHandler(_ req: Request) throws
    -> EventLoopFuture<Article> {
        let updateData = try req.content.decode(UpdateArticleData.self)
        return Article.find(
            req.parameters.get(ApiPath.articleId.rawValue),
            on: req.db)
        .unwrap(or: Abort(.notFound)).flatMapThrowing { article -> Article in
            let userAuth = try req.auth.require(User.self)
            guard article.$user.id == userAuth.id else {
                throw Abort(.unauthorized)
            }
            article.title = updateData.title != nil ? updateData.title! : article.title
            article.description = updateData.description != nil ? updateData.description! : article.description
            article.picture = updateData.picture != nil ? updateData.picture! : article.picture
            return article
        }
        .flatMap { article in
            article.save(on: req.db).map { article }
        }
    }

    func deleteHandler(_ req: Request)
    -> EventLoopFuture<HTTPStatus> {
        Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { article -> EventLoopFuture<HTTPStatus> in
                let userAuth = try req.auth.require(User.self)
                guard article.$user.id == userAuth.id else {
                    throw Abort(.unauthorized)
                }
                return article.delete(on: req.db)
                    .transform(to: HTTPStatus.noContent)
            }
            .flatMap { $0 }
    }

    func searchHandler(_ req: Request) throws
    -> EventLoopFuture<[Article]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Article.query(on: req.db).group(.or) { or in
            or.filter(\.$title, .custom("ILIKE"), "%\(searchTerm)%")
            or.filter(\.$description, .custom("ILIKE"), "%\(searchTerm)%")
        }.sort(\.$updatedAt, .descending).all()
    }

    func getUserHandler(_ req: Request)
    -> EventLoopFuture<User.Public> {
        Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { article in
                article.$user.get(on: req.db).convertToPublic()
            }
    }

    func getTagsHandler(_ req: Request)
    -> EventLoopFuture<[Tag]> {
        Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { article in
                article.$tags.query(on: req.db).sort(\.$name, .ascending).all()
            }
    }

    func updateTagsHandler(_ req: Request) throws
    -> EventLoopFuture<[Tag]> {
        let tagNames = try req.content.decode([String].self)
        return Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { article -> EventLoopFuture<[Tag]> in
                let userAuth = try req.auth.require(User.self)
                guard article.$user.id == userAuth.id else {
                    throw Abort(.unauthorized)
                }
                return Tag.updateTags(tagNames, for: article, on: req).flatMap { _ in
                    return Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
                        .unwrap(or: Abort(.notFound))
                        .flatMap { article in
                            return article.$tags.get(on: req.db)
                        }
                }.map { $0 }
            }
            .flatMap { $0 }
    }

    func getCommentsHandler(_ req: Request)
    -> EventLoopFuture<[CommentWithAuthor]> {
        return Comment.query(on: req.db)
            .with(\.$author) { authors in }
            .all()
            .flatMapThrowing { comments in
                return comments
                    .filter {
                        $0.$article.id == req.parameters.get(ApiPath.articleId.rawValue)
                    }
                    .sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
                    .map {
                        CommentWithAuthor(
                            id: $0.id,
                            description: $0.description,
                            createdAt: $0.createdAt,
                            author: $0.author.convertToPublic())
                    }
            }
    }

    func createCommentHandler(_ req: Request) throws
    -> EventLoopFuture<Comment> {
        let data = try req.content.decode(CreateCommentData.self)
        return Article.find(req.parameters.get(ApiPath.articleId.rawValue), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { article -> EventLoopFuture<Comment> in
                let user = try req.auth.require(User.self)
                let comment = Comment(
                    description: data.comment,
                    userID: try user.requireID(),
                    articleId: try article.requireID())
                return comment.save(on: req.db).map { comment }
            }
            .flatMap { $0 }
    }
}

struct CreateArticleData: Content {
    let title: String
    let description: String
    let picture: String?
}

struct UpdateArticleData: Content {
    let title: String?
    let description: String?
    let picture: String?

    init(
        title: String? = nil,
        description: String? = nil,
        picture: String? = nil) {
            self.title = title
            self.description = description
            self.picture = picture
        }
}

struct CommentWithAuthor: Content {
    let id: UUID?
    let description: String
    let createdAt: Date?
    let author: User.Public
}

struct CreateCommentData: Content {
    let comment: String
}
