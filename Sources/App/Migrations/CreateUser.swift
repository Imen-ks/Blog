//
//  CreateUser.swift
//
//
//  Created by Imen Ksouri on 10/12/2023.
//

import Foundation
import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field(User.firstName, .string, .required)
            .field(User.lastName, .string, .required)
            .field(User.username, .string, .required)
            .field(User.password, .string, .required)
            .field(User.email, .string, .required)
            .field(User.profilePicture, .string)
            .field(User.createdAt, .datetime)
            .unique(on: User.username)
            .unique(on: User.email)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
