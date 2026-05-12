import SwiftUI

struct TemperatureTrendChart: View {
    let hourlyScores: [HourlyScoreItem]
    let height: CGFloat = 120

    private var displayItems: [HourlyScoreItem] {
        Array(hourlyScores.prefix(12))
    }

    private var maxScore: Double {
        Double(displayItems.map(\.score).max() ?? 100)
    }

    private var minScore: Double {
        Double(displayItems.map(\.score).min() ?? 0)
    }

    var body: some View {
        VStack(spacing: 8) {
            chart
                .frame(height: height)
                .padding(.horizontal, 4)

            timeLabels
        }
    }

    private var chart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let itemWidth = width / CGFloat(max(displayItems.count - 1, 1))
            let range = max(maxScore - minScore, 10)

            ZStack(alignment: .leading) {
                gridLines(width: width, height: height)

                Path { path in
                    for (index, item) in displayItems.enumerated() {
                        let x = CGFloat(index) * itemWidth
                        let normalizedScore = CGFloat(item.score - Int(minScore)) / CGFloat(range)
                        let y = height * (1 - normalizedScore * 0.8) - 10
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prev = displayItems[index - 1]
                            let prevNorm = CGFloat(prev.score - Int(minScore)) / CGFloat(range)
                            let prevY = height * (1 - prevNorm * 0.8) - 10
                            let midX = (x + CGFloat(index - 1) * itemWidth) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                    }
                }
                .stroke(
                    LinearGradient(colors: [.orange, .yellow, .blue], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                ForEach(Array(displayItems.enumerated()), id: \.offset) { index, item in
                    let x = CGFloat(index) * itemWidth
                    let normalizedScore = CGFloat(item.score - Int(minScore)) / CGFloat(range)
                    let y = height * (1 - normalizedScore * 0.8) - 10

                    Circle()
                        .fill(colorForScore(item.score))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private var timeLabels: some View {
        HStack(spacing: 0) {
            let step = max(displayItems.count / 6, 1)
            ForEach(Array(stride(from: 0, to: displayItems.count, by: step)), id: \.self) { index in
                Text(String(format: "%02d:00", displayItems[index].hour))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                Divider()
                    .background(Color.white.opacity(0.06))
                if i < 3 { Spacer() }
            }
        }
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 70...: return .green
        case 50..<70: return .yellow
        case 30..<50: return .orange
        default: return .red
        }
    }
}
