//
//  UserTests.swift
//  
//
//  Created by Imen Ksouri on 03/02/2024.
//

import Foundation
@testable import App
import XCTVapor

final class UserTests: XCTestCase {

    func testUserCanRegister() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let firstName = UUID().uuidString
        let lastName = UUID().uuidString
        let username = UUID().uuidString
        let password = "password"
        let email = "\(username)@test.com"
        let profilePicture = "\(UUID().uuidString).jpg"
        let userData = User(
            firstName: firstName,
            lastName: lastName,
            username: username,
            password: password,
            email: email,
            profilePicture: profilePicture)
        let uri = "/api/users/"

        try app.test(.POST, uri, beforeRequest: { req in
            try req.content.encode(userData)
        }, afterResponse: { res in
            let retrievedUser = try res.content.decode(User.self)
            XCTAssertEqual(retrievedUser.firstName, firstName)
            XCTAssertEqual(retrievedUser.lastName, lastName)
            XCTAssertEqual(retrievedUser.username, username)
            XCTAssertTrue(try Bcrypt.verify(password, created: retrievedUser.password))
            XCTAssertEqual(retrievedUser.email, email)
            XCTAssertEqual(retrievedUser.profilePicture, profilePicture)
        })
    }

    func testUserCanLoginWithCorrectCredentialsAndTokenIsGenerated() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let firstName = UUID().uuidString
        let lastName = UUID().uuidString
        let username = UUID().uuidString
        let user = try User.create(
            firstName: firstName,
            lastName: lastName,
            username: username,
            on: app.db)
        let uri = "/api/users/login/"

        try app.test(.POST, uri, loggedInRequest: true, loggedInUser: user, beforeRequest: { req in
            req.headers.basicAuthorization =
              .init(username: user.username, password: "password")
        }, afterResponse: { res in
            let generatedToken = try res.content.decode(Token.self)
            XCTAssertEqual(generatedToken.$user.id, user.id)
        })
    }

    func testUserCannotLoginWithIncorrectCredentials() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let firstName = UUID().uuidString
        let lastName = UUID().uuidString
        let username = UUID().uuidString
        let user = try User.create(
            firstName: firstName,
            lastName: lastName,
            username: username,
            on: app.db)
        let uri = "/api/users/login/"

        try app.test(.POST, uri, loggedInRequest: true, loggedInUser: user, beforeRequest: { req in
            req.headers.basicAuthorization =
              .init(username: user.username, password: "wrongPassword")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testAllUsersCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let database = await TestDatabase.init(on: app.db)
        let usersAtStart = database.users.count
        let randomCount = Int.random(in: 1...100)
        var usersCreated: [User.Public] = []
        for _ in 1...randomCount {
            usersCreated.append(try User.create(on: app.db).convertToPublic())
        }
        XCTAssertEqual(randomCount, usersCreated.count)
        let uri = "/api/users/"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedUsers = try res.content.decode([User.Public].self)
            XCTAssertEqual(retrievedUsers.count, usersAtStart + usersCreated.count)
        })
    }

    func testSingleUserCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let userId = user.id!
        let uri = "/api/users/\(userId)"

        try app.test(.GET, uri, afterResponse: { res in
            let retrievedUser = try res.content.decode(User.Public.self)
            XCTAssertEqual(retrievedUser.id, userId)
            XCTAssertEqual(retrievedUser.firstName, user.firstName)
            XCTAssertEqual(retrievedUser.lastName, user.lastName)
            XCTAssertEqual(retrievedUser.username, user.username)
            XCTAssertEqual(retrievedUser.email, user.email)
            XCTAssertEqual(retrievedUser.profilePicture, user.profilePicture)
        })
    }

    func testAuthorisedUserCanUpdateUser() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let userId = user.id!
        let updatedFirstName = UUID().uuidString
        let updatedLastName = UUID().uuidString
        let updatedUsername = UUID().uuidString
        let updatedPassword = UUID().uuidString
        let updatedEmail = "\(updatedUsername)@test.com"
        let updatedProfilePicture = "\(updatedUsername).jpg"
        let updatedUserData = UpdateUserData(
            firstName: updatedFirstName,
            lastName: updatedLastName,
            username: updatedUsername,
            password: updatedPassword,
            email: updatedEmail,
            profilePicture: updatedProfilePicture)
        let uri = "/api/users/\(userId)"

        try app.test(.PUT, uri, loggedInUser: user, beforeRequest: { req in
            try req.content.encode(updatedUserData)
        }, afterResponse: { res in
            let retrievedUser = try res.content.decode(User.Public.self)
            XCTAssertEqual(retrievedUser.id, userId)
            XCTAssertEqual(retrievedUser.firstName, updatedFirstName)
            XCTAssertEqual(retrievedUser.lastName, updatedLastName)
            XCTAssertEqual(retrievedUser.username, updatedUsername)
            XCTAssertEqual(retrievedUser.email, updatedEmail)
            XCTAssertEqual(retrievedUser.profilePicture, updatedProfilePicture)
        })
    }

    func testNotLoggedInUserCannotUpdateUser() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let userId = user.id!
        let updatedFirstName = UUID().uuidString
        let updatedLastName = UUID().uuidString
        let updatedUsername = UUID().uuidString
        let updatedPassword = UUID().uuidString
        let updatedEmail = "\(updatedUsername)@test.com"
        let updatedProfilePicture = "\(updatedUsername).jpg"
        let updatedUserData = UpdateUserData(
            firstName: updatedFirstName,
            lastName: updatedLastName,
            username: updatedUsername,
            password: updatedPassword,
            email: updatedEmail,
            profilePicture: updatedProfilePicture)
        let uri = "/api/users/\(userId)"

        try app.test(.PUT, uri, beforeRequest: { req in
            try req.content.encode(updatedUserData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUnauthorizedUserCannotUpdateUser() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let userId = user.id!
        let updatedFirstName = UUID().uuidString
        let updatedLastName = UUID().uuidString
        let updatedUsername = UUID().uuidString
        let updatedPassword = UUID().uuidString
        let updatedEmail = "\(updatedUsername)@test.com"
        let updatedProfilePicture = "\(updatedUsername).jpg"
        let updatedUserData = UpdateUserData(
            firstName: updatedFirstName,
            lastName: updatedLastName,
            username: updatedUsername,
            password: updatedPassword,
            email: updatedEmail,
            profilePicture: updatedProfilePicture)
        let unauthorizedUser = try User.create(on: app.db)
        let uri = "/api/users/\(userId)"

        try app.test(.PUT, uri, loggedInUser: unauthorizedUser, beforeRequest: { req in
            try req.content.encode(updatedUserData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUserArticlesCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let userId = user.id!
        let database = await TestDatabase.init(on: app.db)
        let articlesAtStart = try await database.users.first { $0.id == userId }!.$articles.get(on: app.db).count
        let randomCount = Int.random(in: 1...100)
        var articlesCreated: [Article] = []
        for _ in 1...randomCount {
            articlesCreated.append(try Article.create(by: user, on: app.db))
        }
        XCTAssertEqual(randomCount, articlesCreated.compactMap { $0 }.count)
        let uri = "/api/users/\(userId)/articles"
        try app.test(.GET, uri, afterResponse: { res in
            let retrievedArticles = try res.content.decode([Article].self)
            XCTAssertEqual(retrievedArticles.count, articlesAtStart + articlesCreated.count)
        })
    }

    func testUserCommentsWithArticleCanBeRetrieved() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        let user = try User.create(on: app.db)
        let article = try Article.create(on: app.db)
        let userId = user.id!
        let database = await TestDatabase.init(on: app.db)
        let commentsAtStart = try await database.users.first { $0.id == userId }!.$comments.get(on: app.db).count
        let randomCount = Int.random(in: 1...100)
        var commentsCreated: [Comment] = []
        for _ in 1...randomCount {
            commentsCreated.append(try Comment.add(by: user, to: article, on: app.db))
        }
        XCTAssertEqual(randomCount, commentsCreated.compactMap { $0 }.count)
        let uri = "/api/users/\(userId)/comments"

        try app.test(.GET, uri, afterResponse: { res in
            let retrievedComments = try res.content.decode([CommentWithArticle].self)
            XCTAssertEqual(retrievedComments.count, commentsAtStart + commentsCreated.count)
        })
    }
}
