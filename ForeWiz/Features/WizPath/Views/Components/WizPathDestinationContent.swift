import SwiftUI

// MARK: - Destination Selection State

struct WizPathDestinationContent: View {
    @Bindable var viewModel: WizPathViewModel
    let showDestinationPicker: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Map (taller when selecting)
                    WizPathMapView(viewModel: viewModel)
                        .frame(height: geometry.size.height * 0.45)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 10)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

            Spacer(minLength: 16)

            // Destination prompt
            LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.liquidAccent.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.liquidAccent)
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("wizpath_select_destination_title"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text(L10n.text("wizpath_smart_route_planner"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Travel mode picker
                    Picker(L10n.text("wizpath_travel_mode"), selection: $viewModel.travelMode) {
                        ForEach(TravelMode.allCases) { mode in
                            Label(mode.localizedTitle, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.travelMode) { _, newMode in
                        // Only recalculate if there's an active route
                        if viewModel.currentRoute != nil {
                            viewModel.switchTravelMode(to: newMode)
                        }
                    }

                    // Set destination button
                    Button {
                        showDestinationPicker()
                        HapticEngine.shared.selectionChanged()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text(L10n.text("wizpath_select_destination"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.liquidAccent, Color.liquidAccentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .liquidAccent.opacity(0.3), radius: 12, y: 4)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Recent destinations
            if !viewModel.recentDestinations.isEmpty {
                RecentDestinationsScroll(
                    destinations: viewModel.recentDestinations,
                    onSelect: { viewModel.selectRecentDestination($0) }
                )
                .padding(.top, 12)
            }

            Spacer(minLength: 16)

            // Offline banner
            if viewModel.state.isOffline {
                OfflineBanner(retry: { Task { await viewModel.calculateRoute() } })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

                    // Attribution
                    Text(L10n.text("wizpath_powered_by_apple_maps"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Recent Destinations Scroll

struct RecentDestinationsScroll: View {
    let destinations: [RecentDestination]
    let onSelect: (RecentDestination) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(destinations.prefix(5)) { recent in
                    RecentChip(destination: recent) {
                        HapticEngine.shared.medium()
                        onSelect(recent)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Recent Chip

private struct RecentChip: View {
    let destination: RecentDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                Text(destination.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.06), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16))
                .foregroundStyle(Color.warning)

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("wizpath_offline_title"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(L10n.text("wizpath_offline_message"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(L10n.text("wizpath_offline_retry")) {
                retry()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.liquidAccent)
        }
        .padding(12)
        .background(Color.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.warning.opacity(0.15), lineWidth: 0.5)
        )
    }
}
