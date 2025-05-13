//
//  Expense.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import SQLite

struct Expense: Identifiable, Equatable {
  let id: Int64
  let merchant: String
  let category: String
  let amount: Double
  let receiptImageURL: URL?
  let timestamp: Date

  // Implementing Equatable Protocol.
  static func == (lhs: Expense, rhs: Expense) -> Bool {
    return lhs.id == rhs.id && lhs.merchant == rhs.merchant && lhs.category == rhs.category
      && lhs.amount == rhs.amount && lhs.receiptImageURL == rhs.receiptImageURL
      && lhs.timestamp == rhs.timestamp
  }
}

extension Expense {
  func asDictionary() -> [String: Any] {
    return [
      "id": id,
      "merchant": merchant,
      "category": category,
      "amount": amount,
      "receiptImageURL": receiptImageURL?.absoluteString as Any,
      "timestamp": timestamp,
    ]
  }

  static func fromRow(_ row: Row) -> Expense {
    return Expense(
      id: row[Expression<Int64>("id")],
      merchant: row[Expression<String>("merchant")],
      category: row[Expression<String>("category")],
      amount: row[Expression<Double>("amount")],
      receiptImageURL: row[Expression<String?>("receiptImageURL")].flatMap(URL.init(string:)),
      timestamp: Date(timeIntervalSince1970: row[Expression<Double>("timestamp")])
    )
  }
}
