//
//  Category.swift
//  today
//

import Foundation

// A label for grouping tasks. Comes with built-in defaults but users can add their own.
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }

    static let defaultCategories: [Category] = [
        Category(name: "work", isDefault: true),
        Category(name: "home", isDefault: true),
        Category(name: "errand", isDefault: true),
        Category(name: "self", isDefault: true)
    ]
}
