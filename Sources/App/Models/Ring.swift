import Fluent
import Vapor

final class Ring: Model {
  static let schema = "rings"

  @ID
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Children(for: \.$ring)
  var languages: [Language]

  init() { }

  init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
  }
}

extension Ring: Content { }
