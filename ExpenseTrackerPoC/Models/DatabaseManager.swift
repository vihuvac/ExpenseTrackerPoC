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
          amount REAL NOT NULL DEFAULT 0.0,
          timestamp REAL NOT NULL
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
    let timestamp = Expression<Double>("timestamp")
    
    try db.run(table.insert(
      id <- expense.id,
      merchant <- expense.merchant,
      category <- expense.category,
      amount <- expense.amount,
      timestamp <- expense.timestamp.timeIntervalSince1970
    ))
  }
  
  func updateExpense(_ expense: Expense) throws {
    guard let db = db else { throw NSError(domain: "Database not initialized", code: -1) }
    
    let table = Table("expense")
    let id = Expression<Int64>("id")
    let merchant = Expression<String>("merchant")
    let category = Expression<String>("category")
    let amount = Expression<Double>("amount")
    let timestamp = Expression<Double>("timestamp")
    
    let row = table.filter(id == expense.id)
    try db.run(row.update(
      merchant <- expense.merchant,
      category <- expense.category,
      amount <- expense.amount,
      timestamp <- expense.timestamp.timeIntervalSince1970
    ))
  }
  
  func loadExpenses() throws -> [Expense] {
    guard let db = db else { throw NSError(domain: "Database not initialized", code: -1) }
    
    let table = Table("expense")
    let id = Expression<Int64>("id")
    let merchant = Expression<String>("merchant")
    let category = Expression<String>("category")
    let amount = Expression<Double>("amount")
    let timestamp = Expression<Double>("timestamp")
    
    return try db.prepare(table).map { row in
      Expense(
        id: row[id],
        merchant: row[merchant],
        category: row[category],
        amount: row[amount],
        timestamp: Date(timeIntervalSince1970: row[timestamp])
      )
    }
  }
  
  func deleteExpense(id: Int64) throws {
    guard let db = db else { throw NSError(domain: "Database not initialized", code: -1) }
    
    let table = Table("expense")
    let rowId = Expression<Int64>("id")
    try db.run(table.filter(rowId == id).delete())
  }
  
  func exportToCSV() throws -> URL {
    let expenses = try loadExpenses()
    let csv = ["id,merchant,category,amount,timestamp"] +
      expenses.map { expense in
        "\(expense.id),\"\(expense.merchant)\",\(expense.category),\(expense.amount),\(expense.timestamp.timeIntervalSince1970)"
      }
    let data = csv.joined(separator: "\n").data(using: .utf8)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("expenses.csv")
    try data.write(to: url)
    return url
  }
  
  func importFromCSV(url: URL) throws {
    let data = try Data(contentsOf: url)
    guard let content = String(data: data, encoding: .utf8) else { throw NSError(domain: "Invalid CSV", code: -1) }
    
    let rows = content.components(separatedBy: "\n").dropFirst() // Skip header
    for row in rows {
      let columns = row.split(separator: ",").map { String($0) }
      if columns.count == 5, let id = Int64(columns[0]), let amount = Double(columns[3]), let timestamp = Double(columns[4]) {
        let expense = Expense(
          id: id,
          merchant: columns[1].trimmingCharacters(in: .init(charactersIn: "\"")),
          category: columns[2],
          amount: amount,
          timestamp: Date(timeIntervalSince1970: timestamp)
        )
        try saveExpense(expense)
      }
    }
  }
}
