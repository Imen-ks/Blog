//
//  File.swift
//  
//
//  Created by Imen Ksouri on 02/02/2024.
//

import Foundation
@testable import App
import Fluent
import Vapor

extension App.User {
    static func create(
        firstName: String = UUID().uuidString,
        lastName: String = UUID().uuidString,
        username: String = UUID().uuidString,
        on database: Database
    ) throws -> User {
        let password = try Bcrypt.hash("password")
        let user = User(
            firstName: firstName,
            lastName: lastName,
            username: username,
            password: password,
            email: "\(username)@test.com")
        try user.save(on: database).wait()
        return user
    }
}

extension App.Tag {
    static func add(
        _ name: String = UUID().uuidString,
        to article: Article,
        on database: Database
    ) async throws -> Tag {
        let tag = try await Tag.query(on: database)
            .filter(\.$name == name.lowercased())
            .first()
        
        if let existingTag = tag {
            try await article.$tags.attach(existingTag, on: database)
            return existingTag
        } else {
            let tag = Tag(name: name.lowercased())
            try await tag.save(on: database)
            try await article.$tags.attach(tag, on: database)
            return tag
        }
    }
}

extension App.Article {
    static func create(
        title: String = UUID().uuidString,
        description: String = UUID().uuidString,
        by user: User? = nil,
        on database: Database
    ) throws -> Article {
        var articleUser = user

        if articleUser == nil {
            articleUser = try User.create(on: database)
        }

        let article = Article(
            title: title,
            description: description,
            userID: articleUser!.id!)
        try article.save(on: database).wait()
        return article
    }
}

extension App.Comment {
    static func add(
        description: String = UUID().uuidString,
        by user: User? = nil,
        to article: Article,
        on database: Database
    ) throws -> Comment {
        guard let user = user else {
            throw Abort(.unauthorized)
        }
        let comment = Comment(
            description: description,
            userID: try user.requireID(),
            articleId: try article.requireID())
        try comment.save(on: database).wait()
        return comment
    }
}
