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
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        
        authSessionsRoutes.get(WebsitePath.login.component, use: loginHandler)
        credentialsAuthRoutes.post(WebsitePath.login.component, use: loginPostHandler)
        authSessionsRoutes.post(WebsitePath.logout.component, use: logoutHandler)
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
            let userId = token.$user.id.uuidString
            req.session.data[SessionDataVariable.userId] = userId
            return req.eventLoop.future(req.redirect(to: WebsiteHostUrl.root))
        }.flatMap { response in return response}
    }
    
    func logoutHandler(_ req: Request) -> Response {
        req.session.data[SessionDataVariable.userId] = nil
        req.auth.logout(User.self)
        return req.redirect(to: WebsiteHostUrl.root)
    }
}
