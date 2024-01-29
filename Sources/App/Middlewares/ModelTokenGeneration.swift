//
//  ModelTokenGeneration.swift
//
//
//  Created by Imen Ksouri on 04/01/2024.
//

import Foundation
import Vapor
import NIOCore
import FluentKit

public protocol ModelTokenGeneration: Model, Authenticatable {
    associatedtype User: Model & Authenticatable
    static var userKey: KeyPath<Self, Parent<User>> { get }
}

extension ModelTokenGeneration {
    public static func generateToken(
        database: DatabaseID? = nil
    ) -> Middleware {
        ModelTokenGenerator<Self.User>(database: database)
    }
    
    var _$user: Parent<User> {
        self[keyPath: Self.userKey]
    }
}

private struct ModelTokenGenerator<User>: RequestTokenGenerator where User: Authenticatable {
    
    public let database: DatabaseID?
    
    func tokenGenerator(request: Request) -> EventLoopFuture<String> {
        return request.redis.get(CacheConstants.token, asJSON: Token.self).flatMap { token in
            guard let token = token else {
                return request.eventLoop.future("")
            }
            return request.eventLoop.future(token.value)
        }
    }
}

public protocol RequestTokenGenerator: Middleware {
    func tokenGenerator(request: Request) -> EventLoopFuture<String>
}

extension RequestTokenGenerator {
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return self.tokenGenerator(request: request).flatMapThrowing { response in
            let auth = BearerAuthorization(token: response)
            request.headers.bearerAuthorization = auth
        }.flatMap {
            next.respond(to: request)
        }
    }
}
