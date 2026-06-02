import SwiftUI

// MARK: - Comfort Score Arc

/// Dairesel konfor puanı göstergesi.
/// 0–100 arası bir değeri çeyrek dairenin altından başlayıp saat yönünde dönen
/// gradient bir yay ile gösterir. Yükleme sonrasında breathing scale animasyonu uygular.
struct ComfortScoreArc: View {
    let score: Int

    @State private var appeared = false

    // Puan aralığına göre gradient renkleri
    private var arcColors: [Color] {
        switch score {
        case 80...100: return [AppTheme.success, Color(hue: 0.38, saturation: 0.7, brightness: 0.9)]
        case 60..<80:  return [AppTheme.warning, AppTheme.sunshine]
        case 40..<60:  return [AppTheme.ember, AppTheme.warning]
        default:       return [AppTheme.danger, AppTheme.coral]
        }
    }

    private var scoreColor: Color { arcColors[0] }

    // Yay, 225° başlangıç açısından saat yönünde 270° döner (alt-sol → alt-sağ)
    private var arcEnd: Double {
        Double(score.clamped(to: 0...100)) / 100.0
    }

    var body: some View {
        ZStack {
            // Arka plan yayı
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(.white.opacity(0.07), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(135))

            // Doldurulan puan yayı
            Circle()
                .trim(from: 0, to: appeared ? arcEnd * 0.75 : 0)
                .stroke(
                    LinearGradient(
                        colors: arcColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
                .animation(.spring(response: 1.1, dampingFraction: 0.72).delay(0.15), value: appeared)

            // Merkez puan metni
            VStack(spacing: 1) {
                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(L10n.text("comfort_score_unit"))
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .textCase(.uppercase)
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.82)
        .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1), value: appeared)
        .onAppear { appeared = true }
        .shadow(color: scoreColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
