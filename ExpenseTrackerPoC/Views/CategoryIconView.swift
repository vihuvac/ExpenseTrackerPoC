//
//  CategoryIconView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI
import UIKit

struct CategoryIconView: View {
  let category: String
  let size: CGFloat

  var body: some View {
    Image(systemName: iconName(for: category))
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
      .foregroundColor(iconColor(for: category))
      .background(
        Circle()
          .fill(Color(UIColor.systemBackground))
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
      )
  }

  private func iconName(for category: String) -> String {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _
      where normalizedCategory.contains("dining") || normalizedCategory.contains("food")
      || normalizedCategory.contains("restaurant"):
      return "fork.knife.circle.fill"
    case _
      where normalizedCategory.contains("transport") || normalizedCategory.contains("travel")
      || normalizedCategory.contains("car"):
      return "car.circle.fill"
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return "cart.circle.fill"
    case _
      where normalizedCategory.contains("grocery") || normalizedCategory.contains("supermarket"):
      return "basket.circle.fill"
    case _
      where normalizedCategory.contains("entertain") || normalizedCategory.contains("movie")
      || normalizedCategory.contains("game"):
      return "tv.circle.fill"
    case _
      where normalizedCategory.contains("health") || normalizedCategory.contains("medical")
      || normalizedCategory.contains("doctor"):
      return "cross.circle.fill"
    case _
      where normalizedCategory.contains("utility") || normalizedCategory.contains("bill")
      || normalizedCategory.contains("electric"):
      return "bolt.circle.fill"
    case _
      where normalizedCategory.contains("education") || normalizedCategory.contains("book")
      || normalizedCategory.contains("school"):
      return "book.circle.fill"
    case _
      where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics")
      || normalizedCategory.contains("computer"):
      return "tv.circle.fill"
    case _ where normalizedCategory.contains("clothing") || normalizedCategory.contains("apparel"):
      return "tag.circle.fill"
    case _ where normalizedCategory.contains("home") || normalizedCategory.contains("furniture"):
      return "house.circle.fill"
    case _ where normalizedCategory.contains("gift") || normalizedCategory.contains("present"):
      return "gift.circle.fill"
    case _
      where normalizedCategory.contains("subscription") || normalizedCategory.contains("service"):
      return "repeat.circle.fill"
    default:
      return "dollarsign.circle.fill" // Default icon
    }
  }

  private func iconColor(for category: String) -> Color {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalizedCategory {
    case _ where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
      return .orange
    case _ where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
      return .blue
    case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
      return .green
    case _ where normalizedCategory.contains("grocery"):
      return .green
    case _ where normalizedCategory.contains("entertain"):
      return .purple
    case _ where normalizedCategory.contains("health") || normalizedCategory.contains("medical"):
      return .red
    case _ where normalizedCategory.contains("utility") || normalizedCategory.contains("bill"):
      return .yellow
    case _ where normalizedCategory.contains("education"):
      return .indigo
    case _ where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
      return .gray
    case _ where normalizedCategory.contains("clothing"):
      return .pink
    case _ where normalizedCategory.contains("home"):
      return .brown
    default:
      return .blue
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    HStack(spacing: 15) {
      CategoryIconView(category: "Dining", size: 40)
      CategoryIconView(category: "Transportation", size: 40)
      CategoryIconView(category: "Shopping", size: 40)
    }

    HStack(spacing: 15) {
      CategoryIconView(category: "Entertainment", size: 40)
      CategoryIconView(category: "Health", size: 40)
      CategoryIconView(category: "Utilities", size: 40)
    }

    HStack(spacing: 15) {
      CategoryIconView(category: "Education", size: 40)
      CategoryIconView(category: "Tech", size: 40)
      CategoryIconView(category: "Other", size: 40)
    }
  }
  .padding()
}
