import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
  app.logger.logLevel = .debug

  app.databases.use(.postgres(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
    username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
    password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
    database: Environment.get("DATABASE_NAME") ?? "vapor_database"
  ), as: .psql)

  app.migrations.add(CreateUser())
  app.migrations.add(CreateToken())
  app.migrations.add(CreateAdminUser())
  app.migrations.add(CreateRing())
  app.migrations.add(SeedRing())
  app.migrations.add(CreateLanguage())
  app.migrations.add(SeedLanguage())

  // register routes
  try routes(app)

  try app.autoMigrate().wait()
}
