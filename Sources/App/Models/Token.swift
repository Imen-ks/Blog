//
//  Token.swift
//
//
//  Created by Imen Ksouri on 24/12/2023.
//

import Foundation
import Vapor
import Fluent

final class Token: Model, Content {
    static let schema = Token.schemaName

    @ID(key: .id)
    var id: UUID?

    @Field(key: Token.value)
    var value: String

    @Parent(key: Token.userID)
    var user: User

    init() {}

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable, ModelTokenGeneration {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    typealias User = App.User
    var isValid: Bool { true }
}

extension Token {
    static let schemaName = "tokens"
    static let id = FieldKey(stringLiteral: "id")
    static let value = FieldKey(stringLiteral: "value")
    static let userID = FieldKey(stringLiteral: "user_ID")
}
