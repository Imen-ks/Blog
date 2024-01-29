//
//  CreateToken.swift
//
//
//  Created by Imen Ksouri on 24/12/2023.
//

import Foundation
import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field(Token.value, .string, .required)
            .field(Token.userID, .uuid, .required,
                   .references(User.schema, User.id, onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}
