//
//  Task.swift
//  today
//

import Foundation

enum Priority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
}

// How far before a task's expiration the user wants to be reminded
enum ReminderOffset: Int, Codable, CaseIterable, Identifiable {
    case atExpiration = 0
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    case threeHours = 180
    case sixHours = 360
    case twelveHours = 720

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .atExpiration: return "at expiration"
        case .fiveMinutes: return "5 min before"
        case .fifteenMinutes: return "15 min before"
        case .thirtyMinutes: return "30 min before"
        case .oneHour: return "1 hour before"
        case .twoHours: return "2 hours before"
        case .threeHours: return "3 hours before"
        case .sixHours: return "6 hours before"
        case .twelveHours: return "12 hours before"
        }
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

// A single thing the user wants to get done today
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var note: String?
    var expirationDate: Date?
    var reminderOffset: ReminderOffset?
    var category: Category
    var priority: Priority
    var isCompleted: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        expirationDate: Date? = nil,
        reminderOffset: ReminderOffset? = nil,
        category: Category,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.expirationDate = expirationDate
        self.reminderOffset = reminderOffset
        self.category = category
        self.priority = priority
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, title, note, expirationDate, reminderOffset, category, priority, isCompleted, sortOrder
    }

    // Handles tasks saved before sortOrder was added
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        reminderOffset = try container.decodeIfPresent(ReminderOffset.self, forKey: .reminderOffset)
        category = try container.decode(Category.self, forKey: .category)
        priority = try container.decode(Priority.self, forKey: .priority)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}
