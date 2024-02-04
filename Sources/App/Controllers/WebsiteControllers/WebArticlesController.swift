//
//  WebArticlesController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebArticlesController: RouteCollection {
    let imageFolder = WorkingDirectory.articlePicturesFolder

    func boot(routes: RoutesBuilder) throws {
        // PATH COMPONENTS
        let articles = WebsitePath.articles.component
        let articleId = WebsitePath.articleId.component
        let create = WebsitePath.create.component
        let addArticlePicture = WebsitePath.addArticlePicture.component
        let edit = WebsitePath.edit.component
        let delete = WebsitePath.delete.component
        let search = WebsitePath.search.component
        let comments = WebsitePath.comments.component

        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        let protectedRoutes = authSessionsRoutes
            .grouped(Token.generateToken(), User.redirectMiddleware(path: WebsiteEndpoint.login.url))

        authSessionsRoutes.get(use: indexHandler)
        authSessionsRoutes
            .grouped(GetArticleUserMiddleware(), GetArticleMiddleware(), GetArticleTagsMiddleware(), GetArticleCommentsMiddleware())
            .get(articles, articleId, use: articleHandler)
        protectedRoutes.get(articles, create, use: createArticleHandler)
        protectedRoutes.post(articles, create, use: createArticlePostHandler)
        protectedRoutes.get(articles, articleId, addArticlePicture, use: addArticlePictureHandler)
        protectedRoutes.on(.POST, articles, articleId, addArticlePicture,
            body: .collect(maxSize: "10mb"),
            use: addArticlePicturePostHandler)
        protectedRoutes
            .grouped(GetArticleUserMiddleware(), GetArticleMiddleware(), GetArticleTagsMiddleware(), GetArticleCommentsMiddleware())
            .get(articles, articleId, edit, use: editArticleHandler)
        protectedRoutes.post(articles, articleId, edit, use: editArticlePostHandler)
        protectedRoutes.post(articles, articleId, delete, use: deleteArticleHandler)
        authSessionsRoutes.get(search, use: searchArticleHandler)
        protectedRoutes.post(articles, articleId, comments, use: addCommentPostHandler)
    }

    func indexHandler(_ req: Request) throws 
    -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        let showCookieMessage = req.cookies["cookies-accepted"] == nil
        let uri = URI(string: ApiEndpoint.articles.url)
        return req.client.get(uri) { _ in }
            .flatMapThrowing { response -> [Article] in
                guard response.status == .ok else {
                    throw Abort(.notFound)
                }
                return try response.content.decode([Article].self)
            }.flatMap { articles in
                let context = IndexContext(
                    articles: articles,
                    userLoggedIn: userLoggedIn,
                    showCookieMessage: showCookieMessage)
                return req.view.render(WebsiteView.index.leafRenderer, context)
            }
    }

    func articleHandler(_ req: Request) throws 
    -> EventLoopFuture<View> {
        let articleContext = try req.content.decode(ArticleContext.self)
        return req.view.render(WebsiteView.article.leafRenderer, articleContext)
    }

    func createArticleHandler(_ req: Request) 
    -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        let context: CreateArticleContext
        if let message = req.query[String.self, at: "message"] {
            context = CreateArticleContext(userLoggedIn: userLoggedIn, message: message)
        } else {
            context = CreateArticleContext(userLoggedIn: userLoggedIn)
        }
        return req.view.render(WebsiteView.createArticle.leafRenderer, context)
    }

    func createArticlePostHandler(_ req: Request) throws
    -> EventLoopFuture<Response> {
        do {
            try CreateArticleFormData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            let redirect = req.redirect(
                to: "\(WebsiteEndpoint.articles.url)/\(WebsitePath.create.rawValue)/?message=\(message)")
            return req.eventLoop.future(redirect)
        }
        let data = try req.content.decode(CreateArticleFormData.self)
        let uri = URI(string: "\(ApiEndpoint.articles.url)")
        return req.client.post(uri, headers: req.headers) { clientRequest in
                let articlePostData = CreateArticleData(
                    title: data.title,
                    description: data.description,
                    picture: nil)
                try clientRequest.content.encode(articlePostData)
            }
            .flatMapThrowing { clientResponse in
                guard clientResponse.status == .ok else {
                    if clientResponse.status == .unauthorized {
                        throw Abort(.unauthorized)
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                let article = try clientResponse.content.decode(Article.self)
                guard let id = article.id else {
                    throw Abort(.notFound)
                }
                var tagsFutures: [EventLoopFuture<Void>] = []
                if !data.tags.isEmpty {
                    let addTagUri = URI(string: "\(ApiEndpoint.articles.url)/\(id)/\(ApiPath.tags.rawValue)")
                    tagsFutures.append(req.client.post(addTagUri, headers: req.headers) { clientRequest in
                            try clientRequest.content.encode(data.tags)
                        }.flatMapThrowing { clientResponse in })
                }
                tagsFutures.flatten(on: req.eventLoop).whenSuccess { _ in }
                return req.redirect(to: "\(WebsiteEndpoint.articles.url)/\(id)")
            }
    }

    func addArticlePictureHandler(_ req: Request) throws
    -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        guard let articleId = req.parameters.get(WebsitePath.articleId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)")
        return req.client.get(uri) { _ in }
            .flatMapThrowing { clientResponse -> Article in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode(Article.self)
            }
            .flatMap { article in
                let context = ImageUploadContext(
                    title: WebsiteView.addArticlePicture.title,
                    pictureType: PictureType.article.rawValue,
                    reference: article.title,
                    currentImage: article.picture,
                    userLoggedIn: userLoggedIn,
                    articleId: articleId)
                return req.view.render(WebsiteView.addArticlePicture.leafRenderer, context)
            }
    }

    func addArticlePicturePostHandler(_ req: Request) throws 
    -> EventLoopFuture<Response> {
        let data = try req.content.decode(ImageUploadData.self)
        guard let articleId = req.parameters.get(WebsitePath.articleId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)")
        return req.client.get(uri) { _ in }
            .flatMapThrowing { clientResponse -> Article in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode(Article.self)
            }
            .flatMap { article in
                let name = "\(articleId)-\(UUID()).jpg"
                let path = req.application.directory.workingDirectory +
                imageFolder + name
                return req.fileio
                    .writeFile(.init(data: data.picture), at: path)
                    .flatMap {
                        let editArticleUri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)")
                        return req.client.put(editArticleUri, headers: req.headers) { clientRequest in
                            let data = UpdateArticleData(picture: name)
                            try clientRequest.content.encode(data)
                        }
                        .flatMap { _ in
                            let redirect = req.redirect(to: "\(WebsiteEndpoint.articles.url)/\(articleId)")
                            return redirect.encodeResponse(for: req)
                        }
                    }
            }
    }

    func editArticleHandler(_ req: Request) throws 
    -> EventLoopFuture<View> {
        let context: EditArticleContext
        let userLoggedIn = req.auth.has(User.self)
        let articleContext = try req.content.decode(ArticleContext.self)
        if let message = req.query[String.self, at: "message"] {
            context = EditArticleContext(
                userLoggedIn: userLoggedIn,
                article: articleContext.article,
                tags: articleContext.tags,
                message: message)
        } else {
            context = EditArticleContext(
                userLoggedIn: userLoggedIn,
                article: articleContext.article,
                tags: articleContext.tags)
        }
        return req.view.render(WebsiteView.editArticle.leafRenderer, context)
    }

    func editArticlePostHandler(_ req: Request) throws 
    -> EventLoopFuture<Response> {
        guard let articleId = req.parameters.get(WebsitePath.articleId.rawValue) else {
            throw Abort(.badRequest)
        }
        do {
            try CreateArticleFormData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            let redirect = req.redirect(to:
                                            "\(WebsiteEndpoint.articles.url)/\(articleId)/\(WebsitePath.edit.rawValue)/?message=\(message)")
            return req.eventLoop.future(redirect)
        }
        let updateData = try req.content.decode(CreateArticleFormData.self)
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)")
        return req.client.put(uri, headers: req.headers) { clientRequest in
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
            let article = try clientResponse.content.decode(Article.self)
            guard let id = article.id else {
                throw Abort(.notFound)
            }
            var tagFuture: [EventLoopFuture<Void>] = []
            let editArticleTagsUri = URI(string: "\(ApiEndpoint.articles.url)/\(id)/\(ApiPath.tags.rawValue)")
            tagFuture.append(req.client.post(editArticleTagsUri, headers: req.headers) { clientRequest in
                try clientRequest.content.encode(updateData.tags)
            }.flatMapThrowing { clientResponse in })
            tagFuture.flatten(on: req.eventLoop).whenSuccess { _ in }
            return req.redirect(to: "\(WebsiteEndpoint.articles.url)/\(id)")
        }
    }

    func deleteArticleHandler(_ req: Request) throws
    -> EventLoopFuture<Response> {
        guard let articleId = req.parameters.get(WebsitePath.articleId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)")
        return req.client.delete(uri, headers: req.headers) { clientRequest in }
            .flatMapThrowing { clientResponse in
                guard clientResponse.status == .noContent else {
                    if clientResponse.status == .unauthorized {
                        throw Abort(.unauthorized)
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                return req.redirect(to: WebsiteHostUrl.root)
            }
    }

    func searchArticleHandler(_ req: Request) 
    -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        if let searchTerm = req.query[String.self, at: "term"] {
            let uri = URI(string: "\(ApiEndpoint.articles.url)/\(ApiPath.search.rawValue)?term=\(searchTerm)")
            return req.client.get(uri) { clientRequest in }
                .flatMapThrowing { clientResponse -> [Article] in
                    return try clientResponse.content.decode([Article].self)
                }
                .flatMap { articles in
                    let context = SearchContext(
                        title: searchTerm,
                        articles: articles,
                        userLoggedIn: userLoggedIn)
                    return req.view.render(WebsiteView.searchArticle.leafRenderer, context)
                }
        } else {
            let context = SearchContext(
                title: WebsiteView.searchArticle.title,
                articles: [],
                userLoggedIn: userLoggedIn)
            return req.view.render(WebsiteView.searchArticle.leafRenderer, context)
        }
    }

    func addCommentPostHandler(_ req: Request) throws 
    -> EventLoopFuture<Response> {
        guard let articleId = req.parameters.get(WebsitePath.articleId.rawValue) else {
            throw Abort(.badRequest)
        }
        do {
            try CreateCommentFormData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            let redirect = req.redirect(
                to: "\(WebsiteEndpoint.articles.url)/\(articleId)/?message=\(message)")
            return req.eventLoop.future(redirect)
        }
        let data = try req.content.decode(CreateCommentFormData.self)
        guard let _ = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let uri = URI(string: "\(ApiEndpoint.articles.url)/\(articleId)/\(ApiPath.comments.rawValue)")
        return req.client.post(uri, headers: req.headers) { clientRequest in
            let commentPostData = CreateCommentData(comment: data.comment)
            try clientRequest.content.encode(commentPostData)
        }
        .flatMapThrowing { clientResponse in
            guard clientResponse.status == .ok else {
                if clientResponse.status == .unauthorized {
                    throw Abort(.unauthorized)
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return req.redirect(to: "\(WebsiteEndpoint.articles.url)/\(articleId)")
        }
    }
}
