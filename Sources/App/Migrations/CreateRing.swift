import Fluent

struct CreateRing: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("rings")
      .id()
      .field("name", .string, .required)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("rings").delete()
  }
}
