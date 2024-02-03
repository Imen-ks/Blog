//
//  TestDatabase.swift
//
//
//  Created by Imen Ksouri on 02/02/2024.
//

import Foundation
@testable import App
import XCTVapor
import Fluent

struct TestDatabase {
    var users: [User] = []
    var tags: [Tag] = []
    var articles: [Article] = []
    var comments: [Comment] = []
    
    init(on database: Database) async {
        do {
            try await getUsers(on: database)
            try await getTags(on: database)
            try await getArticles(on: database)
            try await getComments(on: database)
        } catch {
            print(error.localizedDescription)
        }
    }

    mutating func getUsers(on database: Database) async throws {
        self.users = try await User.query(on: database).all()
    }

    mutating func getTags(on database: Database) async throws {
        self.tags = try await Tag.query(on: database).all()
    }

    mutating func getArticles(on database: Database) async throws {
        self.articles = try await Article.query(on: database).all()
    }

    mutating func getComments(on database: Database) async throws {
        self.comments = try await Comment.query(on: database).all()
    }
}
