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
          .fontWeight(.bold)
          .padding(.top)

        if expenses.isEmpty {
          Text("No expenses to summarize")
            .foregroundColor(.gray)
            .padding()
        } else {
          // Total expenses card
          VStack {
            Text("Total Expenses")
              .font(.headline)
              .foregroundColor(.secondary)

            Text("$\(String(format: "%.2f", totalExpenses))")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor(.primary)
              .padding(.top, 4)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(12)
          .padding(.horizontal)

          // Pie chart with legend
          VStack(spacing: 16) {
            PieChartView(totalsByCategory: totalsByCategory, total: totalExpenses)
              .frame(height: 200)
              .padding(.top, 8)

            // Legend
            VStack(alignment: .leading, spacing: 0) {
              Text("Categories")
                .font(.headline)
                .padding(.bottom, 8)
                .padding(.horizontal)

              ForEach(sortedCategories.indices, id: \.self) { index in
                let (category, amount) = sortedCategories[index]
                let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0

                VStack(spacing: 0) {
                  HStack(spacing: 12) {
                    Circle()
                      .fill(getColorForCategory(category, index: index))
                      .frame(width: 12, height: 12)

                    Text(category)
                      .font(.subheadline)

                    Spacer()

                    Text("\(String(format: "%.1f", percentage))%")
                      .font(.subheadline)
                      .foregroundColor(getColorForCategory(category, index: index))
                      .fontWeight(.medium)

                    Text("$\(String(format: "%.2f", amount))")
                      .font(.subheadline)
                      .foregroundColor(.primary)
                  }
                  .padding(.vertical, 8)
                  .padding(.horizontal)

                  if index < sortedCategories.count - 1 {
                    Divider()
                      .padding(.leading)
                  }
                }
              }
            }
          }
          .padding(.bottom, 8)
          .background(Color(.systemBackground))
          .cornerRadius(12)
          .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
          .padding(.horizontal)

          VStack(alignment: .leading, spacing: 10) {
            Text("Breakdown by Category")
              .font(.headline)
              .padding(.horizontal)
              .padding(.top, 8)

            ForEach(sortedCategories, id: \.category) { category, total in
              VStack(alignment: .leading, spacing: 8) {
                // Category header with icon
                HStack {
                  Image(systemName: iconName(for: category))
                    .foregroundColor(getColorForCategory(category, index: 0))
                    .padding(.trailing, 4)

                  Text(category)
                    .font(.subheadline)
                    .fontWeight(.bold)

                  Spacer()

                  Text("$\(String(format: "%.2f", total))")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
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

  private func iconName(for category: String) -> String {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _
      where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
      return "fork.knife.circle.fill"
    case _
      where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
      return "car.circle.fill"
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return "cart.circle.fill"
    case _
      where normalizedCategory.contains("grocery"):
      return "basket.circle.fill"
    case _
      where normalizedCategory.contains("entertain"):
      return "tv.circle.fill"
    case _
      where normalizedCategory.contains("health") || normalizedCategory.contains("medical"):
      return "cross.circle.fill"
    case _
      where normalizedCategory.contains("utility") || normalizedCategory.contains("bill"):
      return "bolt.circle.fill"
    case _
      where normalizedCategory.contains("education"):
      return "book.circle.fill"
    case _
      where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
      return "laptopcomputer.circle.fill"
    case _ where normalizedCategory.contains("clothing"):
      return "tag.circle.fill"
    case _ where normalizedCategory.contains("home"):
      return "house.circle.fill"
    default:
      return "dollarsign.circle.fill" // Default icon
    }
  }

  private func getColorForCategory(_ category: String, index: Int) -> Color {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _ where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
      return Color.orange
    case _ where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
      return Color.blue
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return Color.green
    case _ where normalizedCategory.contains("grocery"):
      return Color.green
    case _ where normalizedCategory.contains("entertain"):
      return Color.purple
    case _ where normalizedCategory.contains("health") || normalizedCategory.contains("medical"):
      return Color.red
    case _ where normalizedCategory.contains("utility") || normalizedCategory.contains("bill"):
      return Color.yellow
    case _ where normalizedCategory.contains("education"):
      return Color.indigo
    case _ where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
      return Color(red: 0.5, green: 0.5, blue: 0.5) // More visible gray
    case _ where normalizedCategory.contains("clothing"):
      return Color.pink
    case _ where normalizedCategory.contains("home"):
      return Color.brown
    default:
      // Use the same color mapping as in PieChartView for consistency
      let colors: [Color] = [
        Color.blue, Color.green, Color.orange, Color.purple, Color.cyan,
        Color.red, Color.yellow, Color.indigo, Color.pink, Color.brown,
      ]
      return colors[index % colors.count]
    }
  }
}

struct PieChartView: View {
  let totalsByCategory: [String: Double]
  let total: Double

  // Use the same colors as in the SummaryView for consistency
  private let colors: [Color] = [
    .blue, .green, .orange, .purple, .cyan, .red, .yellow, .indigo, .pink, .brown,
  ]

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // First draw all the pie segments
        ForEach(Array(totalsByCategory.sorted { $0.value > $1.value }.enumerated()), id: \.offset) {
          index, entry in
          PieSegment(
            startAngle: self.startAngle(for: index),
            endAngle: self.endAngle(for: index),
            category: entry.key,
            amount: entry.value,
            total: total,
            index: index
          )
        }

        // Add center white circle for better aesthetics
        Circle()
          .fill(Color(.systemBackground))
          .frame(width: min(geometry.size.width, geometry.size.height) / 2.8)
          .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
      }
      .animation(.easeInOut(duration: 0.5), value: totalsByCategory.count)
    }
  }

  private func startAngle(for index: Int) -> Angle {
    let sorted = totalsByCategory.sorted { $0.value > $1.value }
    var angle: Double = -90 // Start at top

    // Sum all previous segments
    for i in 0 ..< index {
      let value = sorted[i].value
      angle += 360 * (value / total)
    }

    return .degrees(angle)
  }

  private func endAngle(for index: Int) -> Angle {
    let start = startAngle(for: index)
    let sorted = totalsByCategory.sorted { $0.value > $1.value }
    let value = sorted[index].value
    let angle = 360 * (value / total)

    return start + .degrees(angle)
  }

  private func getCategoryColor(_ category: String, index: Int) -> Color {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _ where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
      return Color.orange
    case _ where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
      return Color.blue
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return Color.green
    case _ where normalizedCategory.contains("grocery"):
      return Color.green
    case _ where normalizedCategory.contains("entertain"):
      return Color.purple
    case _ where normalizedCategory.contains("health") || normalizedCategory.contains("medical"):
      return Color.red
    case _ where normalizedCategory.contains("utility") || normalizedCategory.contains("bill"):
      return Color.yellow
    case _ where normalizedCategory.contains("education"):
      return Color.indigo
    case _ where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
      return Color(red: 0.5, green: 0.5, blue: 0.5) // More visible gray
    case _ where normalizedCategory.contains("clothing"):
      return Color.pink
    case _ where normalizedCategory.contains("home"):
      return Color.brown
    default:
      return colors[index % colors.count]
    }
  }
}

struct PieSegment: View {
  let startAngle: Angle
  let endAngle: Angle
  let category: String
  let amount: Double
  let total: Double
  let index: Int

  private var percentage: Double {
    return total > 0 ? amount / total : 0
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // Draw the pie segment
        Path { path in
          path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
          path.addArc(
            center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
            radius: min(geo.size.width, geo.size.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
          )
        }
        .fill(getCategoryColor(category, index: index))

        // Show percentage for larger segments (over 15%)
        if percentage > 0.15 {
          // Calculate position of label
          let midAngle = startAngle + ((endAngle - startAngle) / 2)
          let segmentWidthDegrees = abs((endAngle - startAngle).degrees)

          // Get radius multiplier based on segment size
          let radiusMultiplier = getRadiusMultiplier(segmentWidthDegrees)

          let radius = min(geo.size.width, geo.size.height) * radiusMultiplier
          let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
          let x = center.x + radius * cos(midAngle.radians)
          let y = center.y + radius * sin(midAngle.radians)

          // The percentage label
          Text("\(String(format: "%.1f", percentage * 100))%")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
              ZStack {
                Capsule()
                  .fill(getCategoryColor(category, index: index))

                Capsule()
                  .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
              }
              .shadow(color: Color.black.opacity(0.25), radius: 1.5, x: 0, y: 1)
            )
            .position(x: x, y: y)
        }
      }
    }
  } // Get category color for a specific category name
  private func getCategoryColor(_ category: String, index: Int) -> Color {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _ where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
      return Color.orange
    case _ where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
      return Color.blue
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return Color.green
    case _ where normalizedCategory.contains("grocery"):
      return Color.green
    case _ where normalizedCategory.contains("entertain"):
      return Color.purple
    case _ where normalizedCategory.contains("health") || normalizedCategory.contains("medical"):
      return Color.red
    case _ where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
      return Color(red: 0.5, green: 0.5, blue: 0.5) // More visible gray
    case _ where normalizedCategory.contains("clothing"):
      return Color.pink
    case _ where normalizedCategory.contains("home"):
      return Color.brown
    default:
      let colors: [Color] = [
        .blue, .green, .orange, .purple, .cyan, .red, .yellow, .indigo, .pink, .brown,
      ]
      return colors[index % colors.count]
    }
  }

  // Helper function to determine radius multiplier based on segment width
  private func getRadiusMultiplier(_ segmentWidth: Double) -> Double {
    if segmentWidth < 25 {
      return 0.48 // Push tiny segments further out
    } else if segmentWidth < 45 {
      return 0.42 // Push small segments out
    } else if segmentWidth < 90 {
      return 0.38 // Medium segments
    } else {
      return 0.35 // Large segments
    }
  }
}

#Preview {
  SummaryView(expenses: [
    // Create larger expense values to ensure percentage labels appear (>15%)
    Expense(
      id: Int64(1),
      merchant: "Starbucks",
      category: "Dining",
      amount: 250.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: Int64(2),
      merchant: "Best Buy",
      category: "Electronics",
      amount: 199.98,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: Int64(3),
      merchant: "Uber",
      category: "Transportation",
      amount: 150.00,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: Int64(4),
      merchant: "Target",
      category: "Shopping",
      amount: 85.75,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: Int64(5),
      merchant: "AMC Theaters",
      category: "Entertainment",
      amount: 45.99,
      receiptImageURL: nil,
      timestamp: Date()
    ),
  ])
}
