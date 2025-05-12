//
//  ExpenseIconView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI
import UIKit

struct ExpenseIconView: View {
  let expense: Expense
  let iconSize: CGFloat
  let imageSize: CGFloat

  init(expense: Expense, iconSize: CGFloat = 40, imageSize: CGFloat = 80) {
    self.expense = expense
    self.iconSize = iconSize
    self.imageSize = imageSize
  }

  var body: some View {
    // If there's a receipt image, show it
    if let receiptURL = expense.receiptImageURL,
       let imageData = try? Data(contentsOf: receiptURL),
       let image = UIImage(data: imageData)
    {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(width: imageSize, height: imageSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 1)
        .accessibilityLabel("Receipt image")
    } else {
      // Otherwise show the category icon
      CategoryIconView(category: expense.category, size: iconSize)
        .accessibilityLabel("Category: \(expense.category)")
    }
  }
}

#Preview {
  ExpenseIconView(
    expense: Expense(
      id: 2,
      merchant: "McDonalds",
      category: "Dining",
      amount: 12.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    iconSize: 60.0,
    imageSize: 80.0
  )
}
