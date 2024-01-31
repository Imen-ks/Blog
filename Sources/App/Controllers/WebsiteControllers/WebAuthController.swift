//
//  WebAuthController.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation
import Vapor

struct WebAuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // PATH COMPONENTS
        let login = WebsitePath.login.component
        let logout = WebsitePath.logout.component

        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        
        authSessionsRoutes.get(login, use: loginHandler)
        credentialsAuthRoutes.post(login, use: loginPostHandler)
        authSessionsRoutes.post(logout, use: logoutHandler)
    }

    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return req.view.render(WebsiteView.login.leafRenderer, context)
    }

    func loginPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let credentials = try req.content.decode(Credentials.self)
        let uri = URI(string: "\(ApiEndpoint.users.url)/\(ApiPath.login.rawValue)")
        return req.client.post(uri) { clientRequest in
            let auth = BasicAuthorization(username: credentials.username, password: credentials.password)
            clientRequest.headers.basicAuthorization = auth
        }.flatMapThrowing { clientResponse -> EventLoopFuture<Response> in
            guard clientResponse.status == .ok else {
                let context = LoginContext(loginError: true)
                return req.view.render(WebsiteView.login.leafRenderer, context).encodeResponse(for: req)
            }
            let token = try clientResponse.content.decode(Token.self)
            req.redis.set(CacheConstants.token, toJSON: token).whenComplete { result in
                switch result {
                case .success:
                    print("User logged in and token successfully cached.")
                case .failure(let error):
                    print("Error while caching token: \(error).")
                }
            }
            return req.eventLoop.future(req.redirect(to: WebsiteHostUrl.root))
        }.flatMap { response in return response}
    }

    func logoutHandler(_ req: Request) -> Response {
        req.auth.logout(User.self)
        req.redis.delete(CacheConstants.token).whenComplete { result in
            switch result {
            case .success:
                print("User logged out and token successfully removed from cache.")
            case .failure(let error):
                print("Error while removing token from cache: \(error).")
            }
        }
        return req.redirect(to: WebsiteHostUrl.root)
    }
}
