//
//  Expense.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import SQLite

struct Expense: Identifiable {
  let id: Int64
  let merchant: String
  let category: String
  let amount: Double
  let timestamp: Date

  // Implementing Equatable Protocol.
  static func == (lhs: Expense, rhs: Expense) -> Bool {
    return lhs.id == rhs.id &&
      lhs.merchant == rhs.merchant &&
      lhs.category == rhs.category &&
      lhs.amount == rhs.amount &&
      lhs.timestamp == rhs.timestamp
  }
}

extension Expense {
  func asDictionary() -> [String: Any] {
    return [
      "id": id,
      "merchant": merchant,
      "category": category,
      "amount": amount,
      "timestamp": timestamp.timeIntervalSince1970
    ]
  }

  static func fromRow(_ row: Row) -> Expense {
    return Expense(
      id: row[Expression<Int64>("id")],
      merchant: row[Expression<String>("merchant")],
      category: row[Expression<String>("category")],
      amount: row[Expression<Double>("amount")],
      timestamp: Date(timeIntervalSince1970: row[Expression<Double>("timestamp")])
    )
  }
}
