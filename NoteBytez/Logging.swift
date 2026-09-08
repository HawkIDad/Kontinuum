// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Logging.swift
//  NoteBytez
//

import OSLog

enum LogCategory: String {
    case app
    case sync
    case data
    case ui
    case entitlement
}

enum Log {

    static func logger(_ category: LogCategory) -> Logger {
        return Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.g9Consulting.NoteBytez", category: category.rawValue)
    }

}
