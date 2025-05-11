//
//  SummaryView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-09.
//

import Foundation
import SwiftUI

struct SummaryView: View {
  let expenses: [Expense]

  private var totalsByCategory: [String: Double] {
    Dictionary(grouping: expenses, by: { $0.category })
      .mapValues { $0.reduce(0) { $0 + $1.amount } }
  }

  private var sortedCategories: [(category: String, total: Double)] {
    totalsByCategory
      .sorted { $0.value > $1.value }
      .map { (category: $0.key, total: $0.value) }
  }

  private var expensesByCategory: [String: [Expense]] {
    Dictionary(grouping: expenses, by: { $0.category })
  }

  private var totalExpenses: Double {
    expenses.reduce(0) { $0 + $1.amount }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Expense Summary")
          .font(.title2)
          .padding(.top)

        if expenses.isEmpty {
          Text("No expenses to summarize")
            .foregroundColor(.gray)
            .padding()
        } else {
          PieChartView(totalsByCategory: totalsByCategory, total: totalExpenses)
            .frame(height: 200)
            .padding()

          VStack(alignment: .leading, spacing: 10) {
            Text("Breakdown by Category")
              .font(.headline)
              .padding(.horizontal)

            ForEach(sortedCategories, id: \.category) { category, total in
              VStack(alignment: .leading, spacing: 8) {
                // Category total
                HStack {
                  Text(category)
                    .font(.subheadline)
                    .fontWeight(.bold)
                  Spacer()
                  Text("$\(String(format: "%.2f", total))")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // List of receipts
                if let categoryExpenses = expensesByCategory[category] {
                  ForEach(categoryExpenses.sorted(by: { $0.merchant < $1.merchant }), id: \.id) {
                    expense in
                    HStack {
                      Text(expense.merchant)
                        .font(.subheadline)
                      Spacer()
                      Text("$\(String(format: "%.2f", expense.amount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                  }
                }
              }
              .padding(.bottom, 8)
            }
          }
          .padding(.horizontal)
        }

        Spacer()
      }
    }
  }
}

struct PieChartView: View {
  let totalsByCategory: [String: Double]
  let total: Double

  private let colors: [Color] = [.blue, .green, .orange, .purple, .cyan, .red]

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        let sorted = totalsByCategory.sorted { $0.value > $1.value }
        var startAngle: Angle = .degrees(-90)

        ForEach(sorted.indices, id: \.self) { index in
          let (category, amount) = sorted[index]
          let percentage = total > 0 ? amount / total : 0
          let angle = Angle.degrees(360 * percentage)

          Path { path in
            path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
            path.addArc(
              center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
              radius: min(geometry.size.width, geometry.size.height) / 2,
              startAngle: startAngle,
              endAngle: startAngle + angle,
              clockwise: false
            )
          }
          .fill(colors[index % colors.count])
          .overlay(
            Text(category)
              .font(.caption)
              .foregroundColor(.white)
              .position(
                angleMidpoint(
                  start: startAngle, end: startAngle + angle,
                  center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                  radius: min(geometry.size.width, geometry.size.height) / 3
                )
              )
          )

          Path { path in
            path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
            path.addArc(
              center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
              radius: min(geometry.size.width, geometry.size.height) / 4,
              startAngle: .degrees(0),
              endAngle: .degrees(360),
              clockwise: false
            )
          }
          .fill(Color.white)

          let _ = startAngle += angle
        }
      }
    }
  }

  private func angleMidpoint(start: Angle, end: Angle, center: CGPoint, radius: CGFloat) -> CGPoint {
    let midAngle = (start.radians + end.radians) / 2
    return CGPoint(
      x: center.x + radius * cos(midAngle),
      y: center.y + radius * sin(midAngle)
    )
  }
}

#Preview {
  SummaryView(expenses: [
    Expense(
      id: 1,
      merchant: "Starbucks",
      category: "Dining",
      amount: 20.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 2,
      merchant: "Walmart",
      category: "Electronics",
      amount: 16.98,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 3,
      merchant: "Uber",
      category: "Transportation",
      amount: 15.00,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 4,
      merchant: "McDonalds",
      category: "Dining",
      amount: 12.75,
      receiptImageURL: nil,
      timestamp: Date()
    ),
  ])
}
