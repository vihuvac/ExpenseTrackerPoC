//
//  DatabaseManager.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import SQLite

class DatabaseManager {
  static let shared = DatabaseManager()
  private var db: Connection?
  
  private init() {
    do {
      let path = try FileManager.default
        .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("ExpenseTrackerPoC")
        .appendingPathComponent("expenses.sqlite")
      try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
      let db = try Connection(path.path)
      try db.execute("""
          CREATE TABLE IF NOT EXISTS expense (
              id INTEGER PRIMARY KEY,
              merchant TEXT NOT NULL,
              category TEXT NOT NULL,
              timestamp TEXT NOT NULL
          )
      """)
      self.db = db
    } catch {
      print("Database initialization error: \(error)")
    }
  }
  
  func saveExpense(_ expense: Expense) throws {
    guard let db = db else {
      throw NSError(domain: "Database not initialized", code: -1)
    }
    let table = Table("expense")
    let id = Expression<Int64>("id")
    let merchant = Expression<String>("merchant")
    let category = Expression<String>("category")
    let timestamp = Expression<String>("timestamp")
    
    let formatter = ISO8601DateFormatter()
    let timestampString = formatter.string(from: expense.timestamp)
    
    try db.run(table.insert(
      id <- expense.id,
      merchant <- expense.merchant,
      category <- expense.category,
      timestamp <- timestampString
    ))
  }
  
  func loadExpenses() throws -> [Expense] {
    guard let db = db else {
      throw NSError(domain: "Database not initialized", code: -1)
    }
    let table = Table("expense")
    let id = Expression<Int64>("id")
    let merchant = Expression<String>("merchant")
    let category = Expression<String>("category")
    let timestamp = Expression<String>("timestamp")
    
    let formatter = ISO8601DateFormatter()
    return try db.prepare(table).map { row in
      let timestampString = row[timestamp]
      let date = formatter.date(from: timestampString) ?? Date()
      return Expense(
        id: row[id],
        merchant: row[merchant],
        category: row[category],
        timestamp: date
      )
    }
  }
}
