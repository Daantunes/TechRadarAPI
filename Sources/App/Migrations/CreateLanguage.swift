import Fluent

struct CreateLanguage: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("languages")
      .id()
      .field("name", .string, .required)
//      .field("iconURL", .string, .required)
      .field("ringID", .uuid, .required, .references("rings", "id", onDelete: .cascade))
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("languages").delete()
  }
}
