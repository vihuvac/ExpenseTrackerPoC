//
//  Expense.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation

struct Expense: Identifiable {
  let id: Int64
  let merchant: String
  let category: String
  let amount: Double
  let timestamp: Date
}
