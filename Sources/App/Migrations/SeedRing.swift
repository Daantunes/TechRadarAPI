import Fluent
import Foundation

struct SeedRing: AsyncMigration {
  func prepare(on database: Database) async throws {
    let fileManager = FileManager.default
    let path = fileManager.currentDirectoryPath + "/Resources/rings.json"
    if let data = fileManager.contents(atPath: path) {
      let rings = try JSONDecoder().decode([Ring].self, from: data)
      for ring in rings {
        try await ring.create(on: database)
      }
    } else {
      fatalError("rings.json not found. Set scheme's `Working Directory` to the project's folder and try again.")
    }
  }

  func revert(on database: Database) async throws {
    try await database
      .schema(Ring.schema)
      .delete()
  }
}
