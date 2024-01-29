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
        guard let userId = request.session.data[SessionDataVariable.userId] else {
            return request.eventLoop.future("")
        }
        let db = request.db(self.database)
        return Token.query(on: db)
                .all()
                .flatMapThrowing { tokens in
                    let filteredTokens = tokens.filter { $0._$user.id.uuidString == userId }
                    let token = filteredTokens.first
                    guard let token = token else {
                        return ""
                    }
                    return token.value
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
