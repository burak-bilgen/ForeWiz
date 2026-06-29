import SwiftUI

struct LocationCard: View {
    let location: SavedLocation
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDelete = false

    var body: some View {
        ZStack {

            if showDelete {
                HStack {
                    Spacer()
                    Button {
                        HapticEngine.shared.medium()
                        onDelete()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color(red: 1.0, green: 0.35, blue: 0.3), in: Circle())
                    }
                    .buttonStyle(.fullTapArea)
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.12))
                            .frame(width: 42, height: 42)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(location.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !location.address.isEmpty {
                            Text(location.address)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                            .transition(.scale.combined(with: .opacity))
                    }

                    if isEditing {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isSelected
                                ? Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.25)
                                : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.fullTapArea)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        guard !isEditing else { return }
                        if gesture.translation.width < 0 {
                            offset = max(gesture.translation.width, -60)
                        }
                    }
                    .onEnded { _ in
                        if offset < -30 {
                            withAnimation(AppTheme.cardSpring) {
                                offset = -60
                                showDelete = true
                            }
                        } else {
                            withAnimation(AppTheme.cardSpring) {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
        }
    }
}

struct CurrentLocationCard: View {
    let location: SavedLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)

                    Text(L10n.text("location_currently_selected"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.08),
                        Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.3)
                            : Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.fullTapArea)
    }
}
