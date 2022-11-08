import Fluent
import Vapor

final class Language: Model {
  static let schema = "languages"

  @ID
  var id: UUID?

  @Field(key: "name")
  var name: String

//  @Field(key: "iconURL")
//  var iconURL: String?

  @Parent(key: "ringID")
  var ring: Ring

  init() { }

  init(id: UUID? = nil, name: String, ringID: Ring.IDValue) {
    self.id = id
    self.name = name
    self.$ring.id = ringID
  }
}

extension Language: Content { }

struct LanguageDTO: Content {
  var name: String
//  var iconURL: String?
  var ringID: UUID
}
