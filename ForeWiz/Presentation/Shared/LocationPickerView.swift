import CoreLocation
import MapKit
import SwiftUI

// MARK: - LocationPickerView

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    let onSelect: (SavedLocation) -> Void
    let onLocationsChanged: ([SavedLocation]) -> Void

    @State private var showAddLocation = false
    @State private var editMode: EditMode = .inactive
    @State private var appears = false

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary: Color(red: 0.25, green: 0.48, blue: 0.92),
                secondary: Color(red: 0.15, green: 0.32, blue: 0.75),
                tertiary: Color(red: 0.40, green: 0.65, blue: 1.0)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if savedLocations.isEmpty {
                    emptyState
                } else {
                    locationList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { appears = true }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showAddLocation) {
            ModernAddLocationView { location in
                savedLocations.append(location)
                onLocationsChanged(savedLocations)
            }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 8) {
            Button {
                HapticEngine.shared.light()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            Text(L10n.text("location_picker_title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showAddLocation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                }

                if savedLocations.count > 1 {
                    Button {
                        withAnimation(AppTheme.cardSpring) {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    } label: {
                        Text(editMode == .active ? L10n.text("location_picker_done") : L10n.text("location_picker_edit"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : -10)
        .animation(AppTheme.defaultEaseOut, value: appears)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "mappin.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .scaleEffect(appears ? 1 : 0.6)
            .animation(AppTheme.sheetSpring.delay(AppTheme.defaultDelay), value: appears)

            Text(L10n.text("location_picker_empty"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text(L10n.text("location_picker_empty_hint"))
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddLocation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.text("location_picker_add_first"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.4, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.fullTapArea)
            .opacity(appears ? 1 : 0)
            .animation(AppTheme.slowEaseOut.delay(AppTheme.defaultDelay + 0.17), value: appears)

            Spacer()
        }
    }

    // MARK: - Location List

    private var locationList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                // Current location always on top
                if let current = savedLocations.first(where: { $0.id == "current-location" }) {
                    CurrentLocationCard(
                        location: current,
                        isSelected: current.id == selectedLocationID,
                        onTap: { selectLocation(current) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Other locations
                let others = savedLocations.filter { $0.id != "current-location" }
                if !others.isEmpty {
                    if savedLocations.contains(where: { $0.id == "current-location" }) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                            Text(L10n.text("location_picker_saved"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .textCase(.uppercase)
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    ForEach(others) { location in
                        LocationCard(
                            location: location,
                            isSelected: location.id == selectedLocationID,
                            isEditing: editMode == .active,
                            onTap: { selectLocation(location) },
                            onDelete: { deleteLocation(location) }
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).animation(AppTheme.cardSpring),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                    }
                }

                // Add location button
                Button {
                    showAddLocation = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text(L10n.text("location_picker_add_button"))
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                    .padding(16)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.fullTapArea)
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer().frame(height: 24)
            }
        }
    }

    // MARK: - Actions

    private func selectLocation(_ location: SavedLocation) {
        guard editMode == .inactive else { return }
        HapticEngine.shared.light()
        withAnimation(AppTheme.pressSpring) {
            selectedLocationID = location.id
        }
        onSelect(location)
        dismiss()
    }

    private func deleteLocation(_ location: SavedLocation) {
        guard location.id != "current-location" else { return }
        withAnimation {
            savedLocations.removeAll { $0.id == location.id }
            if selectedLocationID == location.id {
                selectedLocationID = SavedLocation.currentLocation.id
            }
        }
        onLocationsChanged(savedLocations)
        HapticEngine.shared.medium()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With locations") {
    LocationPickerView(
        savedLocations: .constant([
            .currentLocation,
            SavedLocation(name: "İstanbul", latitude: 41.0082, longitude: 28.9784, address: "İstanbul, Turkey"),
            SavedLocation(name: "London", latitude: 51.5074, longitude: -0.1278, address: "London, United Kingdom")
        ]),
        selectedLocationID: .constant("current-location"),
        onSelect: { _ in },
        onLocationsChanged: { _ in }
    )
}

#Preview("Empty") {
    LocationPickerView(
        savedLocations: .constant([]),
        selectedLocationID: .constant("current-location"),
        onSelect: { _ in },
        onLocationsChanged: { _ in }
    )
}
#endif
