import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import Redis
import LeafMarkdown

// configures your application
public func configure(_ app: Application) async throws {
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let databaseURL = Environment.get(ConfigConstants.herokuDatabaseUrl) {
        try configureDatabase(with: databaseURL, for: app)
    } else {
        try configureLocalDatabase(for: app)
    }

    let redisHostname = Environment.get(ConfigConstants.redisHostName) ?? ConfigConstants.defaultRedisHostName
    let redisConfig =
    try RedisConfiguration(hostname: redisHostname)
    app.redis.configuration = redisConfig

    app.migrations.add([
        CreateUser(),
        CreateArticle(),
        CreateTag(),
        CreateArticleTagPivot(),
        CreateComment(),
        CreateToken()
    ])

    // SEED DATA MIGRATION
    app.migrations.add([
        SeedUsers(),
        SeedArticles(),
        SeedTags(),
        SeedArticleTagPivots(),
        SeedComments(),
        SeedTokens()
    ])

    app.logger.logLevel = .debug
    try await app.autoMigrate()

    app.views.use(.leaf)
    app.leaf.tags[ConfigConstants.markdown] = Markdown()
    app.sessions.use(.redis)
    app.middleware.use(app.sessions.middleware)

    // register routes
    try routes(app)

    // Database Configuration for Heroku Deployment
    func configureDatabase(with dbUrl: String, for app: Application) throws {
        guard let url = URL(string: dbUrl), let host = url.host else {
            return
        }

        var tlsConfig: TLSConfiguration = .makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)
        var postgresConfig = try SQLPostgresConfiguration(url: dbUrl)
        postgresConfig.coreConfiguration.tls = .require(nioSSLContext)
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

        app.logger.info("Using Postgres DB \(dbUrl) at \(host)")
    }

    // Local Database Configuration
    func configureLocalDatabase(for app: Application) throws {
        let databaseName: String
        let databasePort: Int
        if (app.environment == .testing) {
            databaseName = ConfigConstants.defaultTestingLocalDatabaseName
            if let testPort = Environment.get(ConfigConstants.localDatabasePort) {
                databasePort = Int(testPort) ?? ConfigConstants.defaultTestingPort
              } else {
                databasePort = ConfigConstants.defaultTestingPort
              }
        } else {
            databaseName = ConfigConstants.defaultDevLocalDatabaseName
            databasePort = ConfigConstants.devPort
        }

        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get(ConfigConstants.localDatabaseHost)
            ?? ConfigConstants.defaultLocalDatabaseHost,
            port: databasePort,
            username: Environment.get(ConfigConstants.localDatabaseUsername)
            ?? ConfigConstants.defaultLocalDatabaseUsername,
            password: Environment.get(ConfigConstants.localDatabasePassword)
            ?? ConfigConstants.defaultLocalDatabasePassword,
            database: Environment.get(ConfigConstants.localDatabaseName)
            ?? databaseName,
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }
}
