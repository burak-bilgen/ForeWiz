import SwiftUI

// MARK: - Climate-Aware Departure Timeline View
struct ClimateAwareTimelineView: View {
    let slots: [DepartureSlot]
    let selectedSlot: DepartureSlot?
    let onSelect: (DepartureSlot) -> Void
    
    @State private var hoveredSlot: DepartureSlot?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with terminal aesthetic
            HStack {
                Text("> DEPARTURE_TIMELINE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#00FF41"))
                
                Spacer()
                
                // Legend
                HStack(spacing: 8) {
                    ClimateLegendItem(color: "#00FF41", label: "Optimal")
                    ClimateLegendItem(color: "#FFCC00", label: "Heat")
                    ClimateLegendItem(color: "#FF3B30", label: "Extreme")
                }
            }
            
            // Timeline bars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(slots) { slot in
                        TimelineBar(
                            slot: slot,
                            isSelected: selectedSlot?.id == slot.id,
                            isHovered: hoveredSlot?.id == slot.id,
                            onTap: { onSelect(slot) }
                        )
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredSlot = isHovered ? slot : nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            
            // Climate warning if extreme heat detected
            if let extremeSlot = slots.first(where: { $0.temperature >= 40 }) {
                ClimateWarningBanner(slot: extremeSlot)
            }
            
            // Selected slot details
            if let selected = selectedSlot {
                SelectedSlotDetail(slot: selected)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#00FF41").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Timeline Bar
struct TimelineBar: View {
    let slot: DepartureSlot
    let isSelected: Bool
    let isHovered: Bool
    let onTap: () -> Void
    
    @State private var heatAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Time label
                Text(slot.timeLabel)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.7))
                
                // Main bar
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor.opacity(0.2))
                        .frame(width: 44, height: 80)
                    
                    // Fill level (represents score/quality)
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(barGradient)
                            .frame(width: 44, height: 80 * fillPercentage)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // Heat overlay effect for extreme temperatures
                    if slot.temperature >= 36 {
                        HeatHazeOverlay(
                            intensity: heatIntensity,
                            isAnimating: heatAnimation
                        )
                    }
                    
                    // Sun flare for extreme heat
                    if slot.temperature >= 40 {
                        SunFlareEffect(
                            intensity: heatAnimation ? 1.0 : 0.7
                        )
                    }
                    
                    // Selection border
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 44, height: 80)
                    }
                }
                .frame(width: 44, height: 80)
                
                // Temperature indicator
                HStack(spacing: 2) {
                    if slot.temperature >= 36 {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(heatColor)
                    }
                    
                    Text("\(Int(slot.temperature))°")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(heatColor)
                }
                
                // Duration label
                Text(slot.durationLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(isSelected ? Color(hex: "#00FF41") : Color.white.opacity(0.5))
            }
            .frame(width: 56)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if slot.temperature >= 36 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    heatAnimation.toggle()
                }
            }
        }
    }
    
    private var barColor: Color {
        if slot.temperature >= 40 {
            return Color(hex: "#FF3B30") // Extreme heat - red
        } else if slot.temperature >= 36 {
            return Color(hex: "#FF9500") // High heat - orange
        } else if slot.temperature >= 32 {
            return Color(hex: "#FFCC00") // Moderate heat - yellow
        } else {
            return Color(hex: "#00FF41") // Optimal - green
        }
    }
    
    private var barGradient: LinearGradient {
        if slot.temperature >= 40 {
            return LinearGradient(
                colors: [Color(hex: "#FF3B30"), Color(hex: "#FF9500")],
                startPoint: .bottom,
                endPoint: .top
            )
        } else if slot.temperature >= 36 {
            return LinearGradient(
                colors: [Color(hex: "#FF9500"), Color(hex: "#FFCC00")],
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "#00FF41"), Color(hex: "#00D9FF")],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }
    
    private var fillPercentage: CGFloat {
        // Lower score if extreme heat
        let baseScore = CGFloat(slot.score) / 100.0
        if slot.temperature >= 40 {
            return baseScore * 0.6 // Reduce by 40% for extreme heat
        } else if slot.temperature >= 36 {
            return baseScore * 0.8 // Reduce by 20% for high heat
        }
        return baseScore
    }
    
    private var heatColor: Color {
        if slot.temperature >= 40 {
            return Color(hex: "#FF3B30")
        } else if slot.temperature >= 36 {
            return Color(hex: "#FF9500")
        }
        return Color.white.opacity(0.5)
    }
    
    private var heatIntensity: Double {
        if slot.temperature >= 40 {
            return 1.0
        } else if slot.temperature >= 36 {
            return 0.6
        }
        return 0.0
    }
}

// MARK: - Heat Haze Overlay
struct HeatHazeOverlay: View {
    let intensity: Double
    let isAnimating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Wavy distortion effect
                ForEach(0..<3) { i in
                    HeatWave(
                        offset: CGFloat(i) * 20,
                        isAnimating: isAnimating,
                        speed: Double(i) * 0.5 + 1.0
                    )
                    .stroke(
                        Color(hex: "#FF9500").opacity(0.3 * intensity),
                        lineWidth: 1
                    )
                }
            }
        }
    }
}

// MARK: - Heat Wave Animation
struct HeatWave: Shape {
    let offset: CGFloat
    let isAnimating: Bool
    let speed: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        for x in stride(from: 0, to: width, by: 2) {
            let normalizedX = Double(x) / Double(width)
            let waveOffset = isAnimating ? sin(normalizedX * 10 + speed) * 5 : 0
            let y = height / 2 + CGFloat(waveOffset) + offset
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - Sun Flare Effect
struct SunFlareEffect: View {
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Central glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#FFCC00").opacity(0.6 * intensity),
                            Color(hex: "#FF9500").opacity(0.3 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: 40, height: 40)
            
            // Rays
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color(hex: "#FFCC00").opacity(0.4 * intensity))
                    .frame(width: 2, height: 25)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }
}

// MARK: - Climate Legend Item
struct ClimateLegendItem: View {
    let color: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
}

// MARK: - Climate Warning Banner
struct ClimateWarningBanner: View {
    let slot: DepartureSlot
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#FF3B30"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("EXTREME HEAT WARNING")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#FF3B30"))
                
                Text("\(Int(slot.temperature))°C at \(slot.timeLabel) - ETA increased by 25%")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#FF3B30").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#FF3B30").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Selected Slot Detail
struct SelectedSlotDetail: View {
    let slot: DepartureSlot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Terminal header
            Text("> SELECTED: \(slot.timeLabel.uppercased())")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "#00FF41"))
            
            HStack(spacing: 16) {
                // Duration
                DetailItem(
                    icon: "clock.fill",
                    label: "Duration",
                    value: slot.durationLabel,
                    color: "#00FF41"
                )
                
                // Temperature
                DetailItem(
                    icon: "thermometer.sun.fill",
                    label: "Temperature",
                    value: "\(Int(slot.temperature))°C",
                    color: slot.temperature >= 40 ? "#FF3B30" : (slot.temperature >= 36 ? "#FF9500" : "#00FF41")
                )
                
                // Score
                DetailItem(
                    icon: "checkmark.shield.fill",
                    label: "Route Score",
                    value: "\(slot.score)/100",
                    color: slot.score >= 70 ? "#00FF41" : (slot.score >= 40 ? "#FFCC00" : "#FF3B30")
                )
            }
            
            // Terminal output
            Text(slot.terminalOutput)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    let color: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: color))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Departure Slot Model
struct DepartureSlot: Identifiable, Sendable {
    let id = UUID()
    let time: Date
    let timeLabel: String
    let durationLabel: String
    let score: Int
    let temperature: Double
    let weatherCondition: SegmentWeatherCondition
    let eta: TimeInterval
    
    var terminalOutput: String {
        if temperature >= 40 {
            return "> CLIMATE_WARNING: Extreme Heat (\(Int(temperature))°C) detected at Destination. ETA adjusted."
        } else if temperature >= 36 {
            return "> CLIMATE_NOTICE: High heat (\(Int(temperature))°C) may affect travel comfort."
        }
        return "> ROUTE_OPTIMAL: Conditions favorable for departure at \(timeLabel)."
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ClimateAwareTimelineView(
            slots: [
                DepartureSlot(
                    time: Date(),
                    timeLabel: "08:00",
                    durationLabel: "2h 15m",
                    score: 85,
                    temperature: 28,
                    weatherCondition: .clear,
                    eta: 8100
                ),
                DepartureSlot(
                    time: Date().addingTimeInterval(3600),
                    timeLabel: "09:00",
                    durationLabel: "2h 20m",
                    score: 78,
                    temperature: 32,
                    weatherCondition: .partlyCloudy,
                    eta: 8400
                ),
                DepartureSlot(
                    time: Date().addingTimeInterval(7200),
                    timeLabel: "10:00",
                    durationLabel: "2h 30m",
                    score: 65,
                    temperature: 36,
                    weatherCondition: .clear,
                    eta: 9000
                ),
                DepartureSlot(
                    time: Date().addingTimeInterval(10800),
                    timeLabel: "11:00",
                    durationLabel: "2h 45m",
                    score: 45,
                    temperature: 42,
                    weatherCondition: .clear,
                    eta: 9900
                ),
                DepartureSlot(
                    time: Date().addingTimeInterval(14400),
                    timeLabel: "12:00",
                    durationLabel: "2h 50m",
                    score: 35,
                    temperature: 44,
                    weatherCondition: .clear,
                    eta: 10200
                )
            ],
            selectedSlot: DepartureSlot(
                time: Date().addingTimeInterval(10800),
                timeLabel: "11:00",
                durationLabel: "2h 45m",
                score: 45,
                temperature: 42,
                weatherCondition: .clear,
                eta: 9900
            ),
            onSelect: { _ in }
        )
        .padding()
    }
}
