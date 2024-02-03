//
//  ConfigConstants.swift
//
//
//  Created by Imen Ksouri on 11/01/2024.
//

import Foundation

struct ConfigConstants {
    //-- MARK: DEVELOPMENT MODE
    // Docker environement variables
    static let localDatabaseName = "DATABASE_NAME"
    static let localDatabaseHost = "DATABASE_HOST"
    static let localDatabaseUsername = "DATABASE_USERNAME"
    static let localDatabasePassword = "DATABASE_PASSWORD"

    // Docker default values
    static let devPort = 5432 // docker default
    static let defaultDevLocalDatabaseName = "vapor_database"
    static let defaultLocalDatabaseHost = "localhost"
    static let defaultLocalDatabaseUsername = "vapor_username"
    static let defaultLocalDatabasePassword = "vapor_password"

    // Redis environment variable name
    static let redisHostName = "REDIS_HOSTNAME"

    // Redis default values
    static let defaultRedisHostName = "localhost"

    // Heroku environement variable, for Heroku deployment
    //https://docs.vapor.codes/deploy/heroku/
    static let herokuDatabaseUrl = "DATABASE_URL"

    //-- MARK: TESTING MODE
    // Postgres default values
    static let defaultTestingPort = 5433
    static let defaultTestingLocalDatabaseName = "vapor-test"

    //-- MARK: LEAF MARKDOWN CUSTOM TAG
    static let markdown = "markdown"
}
