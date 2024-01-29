//
//  WebUsersController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebUsersController: RouteCollection {
    let imageFolder = WorkingDirectory.profilePicturesFolder
    
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
        guard let userId = req.parameters.get(WebsitePath.userId.rawValue) else {
            throw Abort(.badRequest)
        }
        let userLoggedIn = req.auth.has(User.self)
        let user = req.auth.get(User.self)
        let userIsAuthor = user?.id?.uuidString == userId
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
        return req.client.get(uri) { _ in }
            .flatMapThrowing { clientResponse -> User.Public in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode(User.Public.self)
            }
            .flatMap { user in
                let getUserArticlesUri = URI(string: "\(ApiEndpoint.users.url)/\(userId)/\(ApiEndpoint.articles.rawValue)")
                return req.client.get(getUserArticlesUri) { _ in }
                    .flatMapThrowing { clientResponse -> [Article] in
                        guard clientResponse.status == .ok else {
                            throw Abort(.notFound)
                        }
                        return try clientResponse.content.decode([Article].self)
                    }
                    .flatMap { articles in
                        let context = UserContext(
                            title: userIsAuthor ? "My Articles" : "\(user.username) articles",
                            user: user,
                            articles: articles,
                            userLoggedIn: userLoggedIn,
                            userIsAuthor: userIsAuthor)
                        return req.view.render(WebsiteView.userArticles.leafRenderer, context)
                    }
            }
    }
    
    func allUsersHandler(_ req: Request) -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        let uri = URI(string: ApiEndpoint.users.url)
        return req.client.get(uri) { _ in }
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
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let userId = try user.requireID().uuidString
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
        return req.client.get(uri) { _ in }
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
    
    func addProfilePictureHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        guard let userId = req.parameters.get(WebsitePath.userId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
        return req.client.get(uri) { _ in }
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
                    articleId: nil)
                return req.view.render(WebsiteView.addProfilePicture.leafRenderer, context)
            }
    }
    
    func addProfilePicturePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(ImageUploadData.self)
        guard let userId = req.parameters.get(WebsitePath.userId.rawValue) else {
            throw Abort(.badRequest)
        }
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
        return req.client.get(uri) { _ in }
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
                        let editProfileUri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
                        return req.client.put(editProfileUri, headers: req.headers) { clientRequest in
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
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let userId = try user.requireID().uuidString
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
        return req.client.get(uri) { _ in }
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
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let userId = try user.requireID().uuidString
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
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
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let userId = try user.requireID().uuidString
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)")
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
            req.auth.logout(User.self)
            return req.redirect(to: WebsiteEndpoint.login.url)
        }
    }
    
    func userCommentsHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let userLoggedIn = req.auth.has(User.self)
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let userId = try user.requireID().uuidString
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(userId)/\(ApiPath.comments.rawValue)")
        return req.client.get(uri, headers: req.headers) { clientRequest in }
            .flatMapThrowing { clientResponse -> [CommentWithArticle] in
                guard clientResponse.status == .ok else {
                    throw Abort(.notFound)
                }
                return try clientResponse.content.decode([CommentWithArticle].self)
            }
            .flatMap { comments in
                let context = UserCommentsContext(
                    user: user.convertToPublic(),
                    comments: comments,
                    userLoggedIn: userLoggedIn)
                return req.view.render(WebsiteView.userComments.leafRenderer, context)
            }
    }
}

