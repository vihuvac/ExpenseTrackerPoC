//
//  PieSegmentView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI

struct PieSegmentView: View {
  let startAngle: Angle
  let endAngle: Angle
  let category: String
  let amount: Double
  let total: Double
  let index: Int
  
  private var percentage: Double {
    total > 0 ? amount / total : 0
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
          LabelView(
            startAngle: startAngle,
            endAngle: endAngle,
            category: category,
            percentage: percentage,
            index: index,
            size: geo.size
          )
        }
      }
    }
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
        let colors: [Color] = [
          .blue, .green, .orange, .purple, .cyan, .red, .yellow, .indigo, .pink, .brown,
        ]
        return colors[index % colors.count]
    }
  }
}

// Helper view for labels
struct LabelView: View {
  let startAngle: Angle
  let endAngle: Angle
  let category: String
  let percentage: Double
  let index: Int
  let size: CGSize
  
  var body: some View {
    let midAngle = startAngle + ((endAngle - startAngle) / 2)
    let segmentWidthDegrees = abs((endAngle - startAngle).degrees)
    let radiusMultiplier: Double
    
    // Adjust radius multiplier based on segment size
    if segmentWidthDegrees < 25 {
      radiusMultiplier = 0.48 // Tiny segments
    } else if segmentWidthDegrees < 45 {
      radiusMultiplier = 0.42 // Small segments
    } else if segmentWidthDegrees < 90 {
      radiusMultiplier = 0.38 // Medium segments
    } else {
      radiusMultiplier = 0.35 // Large segments
    }
    
    let radius = min(size.width, size.height) * radiusMultiplier
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let x = center.x + radius * cos(midAngle.radians)
    let y = center.y + radius * sin(midAngle.radians)
    
    return Text("\(String(format: "%.1f", percentage * 100))%")
      .font(.system(size: 9, weight: .bold))
      .foregroundColor(.white)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(
        ZStack {
          Capsule()
            .fill(getCategoryColor(category, index: index))
          
          // Inner highlight
          Capsule()
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 1.5, x: 0, y: 1)
      )
      .position(x: x, y: y)
  }
  
  // Get category color
  private func getCategoryColor(_ category: String, index: Int) -> Color {
    let normalizedCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    switch normalizedCategory {
      case _ where normalizedCategory.contains("dining") || normalizedCategory.contains("food"):
        return Color.orange
      case _ where normalizedCategory.contains("transport") || normalizedCategory.contains("travel"):
        return Color.blue
      case _ where normalizedCategory.contains("shop") || normalizedCategory.contains("retail"):
        return Color.green
      case _ where normalizedCategory.contains("entertain"):
        return Color.purple
      case _ where normalizedCategory.contains("tech") || normalizedCategory.contains("electronics"):
        return Color(red: 0.5, green: 0.5, blue: 0.5)
      default:
        let colors: [Color] = [
          .blue, .green, .orange, .purple, .cyan,
        ]
        return colors[index % colors.count]
    }
  }
}

#Preview {
  ZStack {
    Color.gray.opacity(0.1)
      .ignoresSafeArea()
    
    VStack(spacing: 20) {
      Text("Pie Segment Preview")
        .font(.headline)
      
      ZStack {
        // Segments
        PieSegmentView(
          startAngle: .degrees(-90),
          endAngle: .degrees(36),
          category: "Dining",
          amount: 250.0,
          total: 732.22,
          index: 0
        )
        
        PieSegmentView(
          startAngle: .degrees(36),
          endAngle: .degrees(133.2),
          category: "Electronics",
          amount: 200.0,
          total: 732.22,
          index: 1
        )
        
        PieSegmentView(
          startAngle: .degrees(133.2),
          endAngle: .degrees(201.6),
          category: "Transportation",
          amount: 142.0,
          total: 732.22,
          index: 2
        )
        
        PieSegmentView(
          startAngle: .degrees(201.6),
          endAngle: .degrees(244.8),
          category: "Shopping",
          amount: 85.0,
          total: 732.22,
          index: 3
        )
        
        PieSegmentView(
          startAngle: .degrees(244.8),
          endAngle: .degrees(270),
          category: "Entertainment",
          amount: 45.22,
          total: 732.22,
          index: 4
        )
        
        // Center white circle
        Circle()
          .fill(Color.white)
          .frame(width: 100)
          .shadow(radius: 1)
      }
      .frame(width: 280, height: 280)
      .padding()
      .background(Color.white)
      .cornerRadius(16)
      .shadow(radius: 2)
    }
    .padding()
  }
}
