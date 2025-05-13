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
    let start = Date()

    do {
      let path = try FileManager.default
        .url(
          for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        .appendingPathComponent("ExpenseTrackerPoC")
        .appendingPathComponent("expenses.sqlite")

      try FileManager.default.createDirectory(
        at: path.deletingLastPathComponent(), withIntermediateDirectories: true
      )

      let db = try Connection(path.path)
      self.db = db

      // Validate and recreate table if necessary
      try recreateTableIfNeeded()

      print("Database initialized in \(Date().timeIntervalSince(start)) seconds")
    } catch {
      print("Database initialization error: \(error)")
    }
  }

  private func recreateTableIfNeeded() throws {
    guard let db = db else { throw NSError(domain: "Database not initialized", code: -1) }

    // Drop existing table to clear corrupted data
    try db.execute("DROP TABLE IF EXISTS expense")

    // Create table with explicit NOT NULL constraints
    try db.execute(
      """
          CREATE TABLE expense (
              id INTEGER PRIMARY KEY,
              merchant TEXT NOT NULL,
              category TEXT NOT NULL,
              amount REAL NOT NULL DEFAULT 0.0,
              timestamp REAL NOT NULL,
              receiptImageURL TEXT
          )
      """)
  }

  func saveExpense(_ expense: Expense) throws {
    guard let db = db else { throw NSError(domain: "Database not initialized", code: -1) }

    let table = Table("expense")
    let id = Expression<Int64>("id")
    let merchant = Expression<String>("merchant")
    let category = Expression<String>("category")
    let amount = Expression<Double>("amount")
    let timestamp = Expression<Double>("timestamp")
    let receiptImageURL = Expression<String?>("receiptImageURL")

    // Validate timestamp
    guard expense.timestamp.timeIntervalSince1970 > 0 else {
      throw NSError(
        domain: "Invalid timestamp", code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Timestamp must be a valid date"]
      )
    }

    try db.run(
      table.insert(
        id <- expense.id,
        merchant <- expense.merchant,
        category <- expense.category,
        amount <- expense.amount,
        timestamp <- expense.timestamp.timeIntervalSince1970,
        receiptImageURL <- expense.receiptImageURL?.absoluteString
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
    let receiptImageURL = Expression<String?>("receiptImageURL")

    // Validate timestamp
    guard expense.timestamp.timeIntervalSince1970 > 0 else {
      throw NSError(
        domain: "Invalid timestamp", code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Timestamp must be a valid date"]
      )
    }

    let row = table.filter(id == expense.id)
    try db.run(
      row.update(
        merchant <- expense.merchant,
        category <- expense.category,
        amount <- expense.amount,
        timestamp <- expense.timestamp.timeIntervalSince1970,
        receiptImageURL <- expense.receiptImageURL?.absoluteString
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
    let receiptImageURL = Expression<String?>("receiptImageURL")

    return try db.prepare(table).map { row in
      // Safely handle potential null timestamp (though schema enforces NOT NULL)
      let timestampValue = row[timestamp]
      guard timestampValue > 0 else {
        throw NSError(
          domain: "Invalid data", code: -3,
          userInfo: [NSLocalizedDescriptionKey: "Null or invalid timestamp in database"]
        )
      }

      let imageURLString = try? row.get(receiptImageURL)
      let imageURL = imageURLString.flatMap { URL(string: $0) }

      return Expense(
        id: row[id],
        merchant: row[merchant],
        category: row[category],
        amount: row[amount],
        receiptImageURL: imageURL,
        timestamp: Date(timeIntervalSince1970: timestampValue)
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
    let csv =
      ["id,merchant,category,amount,timestamp,receiptImageURL"]
        + expenses.map { expense in
          "\(expense.id),\"\(expense.merchant)\",\(expense.category),\(expense.amount),\(expense.timestamp.timeIntervalSince1970),\(expense.receiptImageURL?.absoluteString ?? "")"
        }
    let data = csv.joined(separator: "\n").data(using: .utf8)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("expenses.csv")
    try data.write(to: url)
    return url
  }

  func importFromCSV(url: URL) throws {
    let data = try Data(contentsOf: url)
    guard let content = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "Invalid CSV", code: -1)
    }

    let rows = content.components(separatedBy: "\n").dropFirst() // Skip header
    for row in rows {
      let columns = row.split(separator: ",").map { String($0) }
      if columns.count >= 5, let id = Int64(columns[0]), let amount = Double(columns[3]),
         let timestamp = Double(columns[4]), timestamp > 0
      {
        let imageURLString = columns.count > 5 ? columns[5] : nil
        let imageURL = imageURLString?.isEmpty == false ? URL(string: imageURLString!) : nil

        let expense = Expense(
          id: id,
          merchant: columns[1].trimmingCharacters(in: .init(charactersIn: "\"")),
          category: columns[2],
          amount: amount,
          receiptImageURL: imageURL,
          timestamp: Date(timeIntervalSince1970: timestamp)
        )
        try saveExpense(expense)
      }
    }
  }
}
