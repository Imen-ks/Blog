//
//  WebRegisterController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebRegisterController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())

        authSessionsRoutes.get(WebsitePath.register.component, use: registerHandler)
        authSessionsRoutes.post(WebsitePath.register.component, use: registerPostHandler)
    }

    func registerHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return req.view.render(WebsiteView.register.leafRenderer, context)
    }

    func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        do {
            try RegisterData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            let redirect = req.redirect(to: "\(WebsiteEndpoint.register.url)?message=\(message)")
            return req.eventLoop.future(redirect)
        }
        let data = try req.content.decode(RegisterData.self)
        let uri = URI(string: ApiEndpoint.users.url)
        return req.client.post(uri) { clientRequest in
            return try clientRequest.content.encode(data)
        }
        .flatMapThrowing { clientResponse -> User in
            guard clientResponse.status == .ok else {
                if clientResponse.status == .unauthorized {
                    throw Abort(.unauthorized)
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return try clientResponse.content.decode(User.self)
        }.flatMap { user in
            let loginUri = URI(string: "\(ApiEndpoint.users.url)/\(ApiPath.login.rawValue)")
            return req.client.post(loginUri) { clientRequest in
                let auth = BasicAuthorization(username: data.username, password: data.password)
                clientRequest.headers.basicAuthorization = auth
            }.flatMapThrowing { clientResponse in
                guard clientResponse.status == .ok else {
                    if clientResponse.status == .unauthorized {
                        throw Abort(.unauthorized)
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                req.auth.login(user)
                let token = try clientResponse.content.decode(Token.self)
                req.redis.set(CacheConstants.token, toJSON: token).whenComplete { result in
                    switch result {
                    case .success:
                        print("User logged in and token successfully cached.")
                    case .failure(let error):
                        print("Error while caching token: \(error).")
                    }
                }
            }.map { _ in
                return req.redirect(to: WebsiteHostUrl.root)
            }
        }
    }
}


