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
      
      // Temporary workaround to delete the existing database in development mode.
      if FileManager.default.fileExists(atPath: path.path) {
        try FileManager.default.removeItem(at: path)
        print("Deleted existing database")
      }
      
      try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
      
      let db = try Connection(path.path)
      try db.execute("""
        CREATE TABLE IF NOT EXISTS expense (
            id INTEGER PRIMARY KEY,
            merchant TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL DEFAULT 0.0,
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
    let amount = Expression<Double>("amount")
    let timestamp = Expression<String>("timestamp")
    
    let formatter = ISO8601DateFormatter()
    let timestampString = formatter.string(from: expense.timestamp)
    
    try db.run(table.insert(
      id <- expense.id,
      merchant <- expense.merchant,
      category <- expense.category,
      amount <- expense.amount,
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
    let amount = Expression<Double>("amount")
    let timestamp = Expression<String>("timestamp")
    
    let formatter = ISO8601DateFormatter()
    return try db.prepare(table).map { row in
      let timestampString = row[timestamp]
      let date = formatter.date(from: timestampString) ?? Date()
      return Expense(
        id: row[id],
        merchant: row[merchant],
        category: row[category],
        amount: row[amount],
        timestamp: date
      )
    }
  }
  
  func deleteExpense(id: Int64) throws {
    guard let db = db else {
      throw NSError(domain: "Database not initialized", code: -1)
    }
    let table = Table("expense")
    let rowId = Expression<Int64>("id")
    try db.run(table.filter(rowId == id).delete())
  }
}
