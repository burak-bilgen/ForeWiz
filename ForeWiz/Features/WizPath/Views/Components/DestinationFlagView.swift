import SwiftUI

// MARK: - Destination Flag

struct DestinationFlag: View {
    @State private var bounce = false

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 30))
            .foregroundStyle(Color.coral)
            .background(
                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
            )
            .scaleEffect(bounce ? 1.1 : 1.0)
            .onAppear {
                withAnimation(AppTheme.cardSpring.repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
    }
}
