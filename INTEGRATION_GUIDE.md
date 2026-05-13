# ForeWiz Yeni Mimarisi - Entegrasyon Rehberi

## 🎯 Hızlı Başlangıç

Yeni refactor edilmiş bileşenleri kullanmak için:

```swift
// 1. DependencyContainer artık yeni servisleri içeriyor
@main
struct ForeWizApp: App {
    let container: DependencyContainer
    
    init() {
        // Artık HapticEngine otomatik hazırlanıyor
        // LocationService timeout ile korunuyor
        // WeatherGradientService hazır
        container = DependencyContainer.live(modelContext: sharedModelContainer.mainContext)
    }
}
```

---

## 🏗️ Yeni Bileşenler

### 1. GlassButton (Apple HIG Uyumlu)

**Önceki:**
```swift
Button(action: {}) {
    Image(systemName: "gear")
        .font(.system(size: 15)) // ❌ 15pt - HIG ihlali
}
```

**Yeni:**
```swift
GlassButton(
    icon: "gearshape.fill",
    accessibilityLabel: "Settings",
    action: {}
) // ✅ 44×44pt garanti

// Veya Toolbar için:
ToolbarSettingsButton(action: {})

// Refresh butonu:
RefreshButton {
    await viewModel.refresh()
}
```

### 2. WeatherGradientService (Dinamik Arka Planlar)

**Önceki:**
```swift
HomeBackground(symbolName: currentSymbol)
    .ignoresSafeArea()
```

**Yeni:**
```swift
WeatherAwareBackground(
    condition: state.currentWeather.conditionText,
    isDaylight: state.currentWeather.isDaylight,
    temperature: currentTemp,
    decision: state.recommendation.outdoorDecision,
    colorScheme: colorScheme
)
// ✅ Hava durumuna göre değişen gradyanlar
// ✅ Gün batımı/şafak renkleri
// ✅ Uyarı durumlarında renk değişimi
```

### 3. MicroInteractionManager (Premium Dokunsal Geri Bildirim)

```swift
// Butonlar
Button("Action") {}
    .microButton()

// Kart giriş animasyonları
HeroCardView(...)
    .microCardEntrance(index: 0, baseDelay: 0.2)

// Refresh animasyonu
RefreshButton { ... }
    .microRefresh(isRefreshing: viewModel.isLoading)

// Hava durumu simge animasyonu
AnimatedWeatherSymbol(
    symbolName: "cloud.rain.fill",
    condition: .rainy
)
```

### 4. WeatherStateTransitionManager (Akıcı Geçişler)

```swift
@StateObject private var transitionManager = WeatherStateTransitionManager.shared

// Hava durumu değiştiğinde:
.onChange(of: viewModel.currentSymbol) { oldValue, newValue in
    let newState = WeatherVisualState(
        from: newValue,
        conditionCode: viewModel.conditionCode,
        isDaylight: viewModel.isDaylight,
        hasAlert: viewModel.hasAlert
    )
    transitionManager.transition(to: newState)
}

// Arka planda interpolasyon:
WeatherAwareBackground(...)
    .weatherTransition(
        from: transitionManager.currentState,
        to: newState,
        progress: transitionManager.transitionProgress
    )
```

### 5. HomeViewStateFactory (ViewModel Kolaylaştırma)

**Önceki (HomeViewModel'de ~500 satır):**
```swift
func makeAssistantState(...) -> HomeAssistantViewState {
    // 150+ satır map işlemi
}
```

**Yeni:**
```swift
// ViewModel'de:
let factory: HomeViewStateFactory

func load() async {
    let result = try await useCase.execute(...)
    let state = factory.makeViewState(from: result, profile: profile)
    self.state = .loaded(state)
}
```

---

## 📦 Yeni View'lar (HomeView Decomposition)

### RefactoredHomeView Kullanımı

```swift
struct ContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        RefactoredHomeView(
            viewModel: viewModel,
            savedLocations: $savedLocations,
            selectedLocationID: $selectedLocationID,
            onRecommendationLoaded: { recommendation in
                // Handle recommendation
            },
            onOpenSettings: {
                showSettings = true
            },
            onLocationsChanged: { locations, selectedID in
                // Update locations
            }
        )
    }
}
```

### Bireysel Kartlar (Gelişmiş Özelleştirme)

```swift
// Hero Card
HeroCardView(
    assistant: state.assistant,
    weather: state.currentWeather,
    recommendation: state.recommendation,
    isUsingCachedWeather: state.isUsingCachedWeather,
    onPrimaryAction: {
        HapticEngine.shared.medium()
        // Handle action
    }
)

// Plan Card
PlanCardView(plan: state.plan)
    .microCardEntrance(index: 2, baseDelay: 0.3)

// Forecast Carousel (Lazy 120fps)
ForecastCarousel(dailyForecasts: state.dailyForecasts)

// Hourly View (Sıcaklık grafiği ile)
HourlyForecastView(hourlyScores: state.hourlyScores)
```

---

## 🔧 Dependency Container Güncellemeleri

### Yeni Eklenen Servisler

```swift
// DependencyContainer artık şunları içeriyor:
let homeViewStateFactory: HomeViewStateFactory
let weatherGradientService: WeatherGradientService
let retryPolicy: NetworkRetryPolicy

// Otomatik hazırlanan:
HapticEngine.shared.prepare() // Launch'ta çağrılır
```

### Kullanım Örneği

```swift
class HomeViewModel: ObservableObject {
    private let container: DependencyContainer
    private let factory: HomeViewStateFactory
    private let gradientService: WeatherGradientService
    
    init(container: DependencyContainer) {
        self.container = container
        self.factory = container.homeViewStateFactory
        self.gradientService = container.weatherGradientService
    }
    
    func refresh() async {
        // Haptic feedback
        HapticEngine.shared.weatherRefresh()
        
        // Retry policy ile veri çekme
        let executor = RetryExecutor(policy: container.retryPolicy)
        
        do {
            let result = try await executor.execute { [self] in
                try await container.loadHomeRecommendationUseCase.execute(...)
            }
            
            // State oluşturma
            let state = factory.makeViewState(from: result, profile: profile)
            
            // Geçiş animasyonu
            await MainActor.run {
                self.state = .loaded(state)
                MicroInteractionManager.shared.triggerDataLoadedHaptic()
            }
            
        } catch {
            MicroInteractionManager.shared.triggerErrorHaptic()
            handleError(error)
        }
    }
}
```

---

## 🎨 Animasyon Sistemi

### 1. Card Entrance Animasyonları

```swift
ScrollView {
    VStack(spacing: 20) {
        HeroCardView(...)
            .cardEntrance(appeared: contentReady, delay: 0.0)
        
        PlanCardView(...)
            .cardEntrance(appeared: contentReady, delay: 0.1)
        
        OutfitCardView(...)
            .cardEntrance(appeared: contentReady, delay: 0.2)
        
        // ...staggered animation
    }
}
```

### 2. Weather State Transitions

```swift
struct WeatherContainerView: View {
    @StateObject private var transitionManager = WeatherStateTransitionManager.shared
    
    var body: some View {
        ZStack {
            // Interpolated background
            WeatherAwareBackground(
                condition: transitionManager.currentState.condition.rawValue,
                ...
            )
            .opacity(1 - transitionManager.transitionProgress)
            
            // Target background
            WeatherAwareBackground(
                condition: newState.condition.rawValue,
                ...
            )
            .opacity(transitionManager.transitionProgress)
        }
        .animation(.easeInOut(duration: 1.5), value: transitionManager.transitionProgress)
    }
}
```

### 3. Mikro-Etkileşimler

```swift
// Buton basış
Button("Tap Me") {}
    .microButton()
    .onLongPressGesture {
        HapticEngine.shared.heavy()
    }

// Kart dokunuşu
PlanCardView(...)
    .contentShape(Rectangle())
    .onTapGesture {
        withAnimation(.spring(response: 0.3)) {
            // Selection logic
        }
        HapticEngine.shared.selectionChanged()
    }
```

---

## ♿ Erişilebilirlik (Accessibility)

### Otomatik Destek

Yeni bileşenler otomatik erişilebilirlik desteği içerir:

```swift
// GlassButton
GlassButton(
    icon: "location.fill",
    accessibilityLabel: "Change location",
    accessibilityHint: "Opens city picker",
    action: {}
)

// Kartlar otomatik combine edilir
HeroCardView(...)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Current weather: 24 degrees, sunny, outdoor score 85")

// Reduce Motion desteği
AnimatedWeatherSymbol(...)
    .environment(\.accessibilityReduceMotion, true) // Animasyonları devre dışı bırakır
```

---

## 🧪 Test Yazma

### HomeViewStateFactory Test Örneği

```swift
import XCTest
@testable import ForeWiz

final class HomeViewStateFactoryTests: XCTestCase {
    var factory: HomeViewStateFactory!
    var mockDateProvider: MockDateProvider!
    
    override func setUp() {
        super.setUp()
        mockDateProvider = MockDateProvider()
        factory = HomeViewStateFactory(
            dateProvider: mockDateProvider,
            activityWindowScoringEngine: MockActivityScoringEngine()
        )
    }
    
    func testMakeAssistantState_WithGoodDecision_ReturnsCorrectTone() {
        // Given
        let result = HomeRecommendationResult(
            recommendation: DailyRecommendation(
                outdoorScore: WeatherScore(rawValue: 85),
                outdoorDecision: .good,
                ...
            ),
            ...
        )
        
        // When
        let state = factory.makeAssistantState(from: result)
        
        // Then
        XCTAssertEqual(state.tone, .good)
        XCTAssertEqual(state.symbolName, "checkmark.seal.fill")
    }
    
    func testMakeViewState_FormatsTemperatureCorrectly() {
        // Given
        let current = CurrentWeatherPoint(
            temperatureCelsius: 24.5,
            ...
        )
        
        // When
        let state = factory.makeCurrentWeatherState(
            from: current,
            dailyPoints: [],
            unitSystem: .metric
        )
        
        // Then
        XCTAssertEqual(state.temperatureText, "24°")
        XCTAssertEqual(state.feelsLikeText, "Feels like 25°")
    }
}
```

---

## 📱 iOS Sürüm Uyumluluğu

| Bileşen | Minimum iOS | Notlar |
|---------|-------------|--------|
| GlassButton | iOS 15+ | .ultraThinMaterial |
| WeatherGradientService | iOS 15+ | LinearGradient |
| MicroInteractionManager | iOS 15+ | Spring animations |
| AnimatedWeatherSymbol | iOS 17+ | SymbolEffect (geri dönüş var) |
| WeatherStateTransitionManager | iOS 15+ | Task API |

---

## 🚀 Performans İpuçları

### 1. Lazy Loading

```swift
// ✅ İyi - LazyHStack kullan
ScrollView(.horizontal) {
    LazyHStack {
        ForEach(forecasts) { forecast in
            ForecastPill(forecast: forecast)
        }
    }
}

// ❌ Kötü - Tüm öğeler hemen oluşturulur
ScrollView(.horizontal) {
    HStack {
        ForEach(forecasts) { forecast in
            ForecastPill(forecast: forecast)
        }
    }
}
```

### 2. Gereksiz Yeniden Hesaplamaları Önleme

```swift
struct WeatherView: View {
    let state: HomeViewState
    
    // ✅ İyi - Hesaplanmış özellikler
    private var backgroundGradient: LinearGradient {
        WeatherGradientService.shared.gradientFor(
            condition: state.currentWeather.conditionText,
            ...
        )
    }
    
    var body: some View {
        backgroundGradient
            .ignoresSafeArea()
    }
}
```

### 3. Haptic Engine Optimizasyonu

```swift
// ✅ İyi - Prepare çağrısı launch'ta bir kez
HapticEngine.shared.prepare()

// ❌ Kötü - Her interaction'da prepare
HapticEngine.shared.light() // prepare() zaten yapıldı
```

---

## 🎓 En İyi Pratikler

### 1. ViewModel'de Factory Kullanımı

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    private let factory: HomeViewStateFactory
    
    init(container: DependencyContainer) {
        self.factory = container.homeViewStateFactory
    }
    
    func load() async {
        do {
            let result = try await useCase.execute(...)
            let profile = try await preferencesRepository.loadProfile()
            
            // Tek çağrı ile tüm state oluşturulur
            let state = factory.makeViewState(
                from: result,
                profile: profile,
                unitSystem: .current
            )
            
            self.state = .loaded(state)
            
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }
}
```

### 2. State Transitions

```swift
// Geçişleri merkezi yönet
.onChange(of: weatherCondition) { old, new in
    let visualState = WeatherVisualState(
        from: new.symbolName,
        conditionCode: new.conditionCode,
        isDaylight: new.isDaylight,
        hasAlert: !new.alerts.isEmpty
    )
    
    // Smooth 1.5s transition
    WeatherStateTransitionManager.shared.transition(to: visualState)
}
```

### 3. Haptic Feedback Dozajı

```swift
// Buton tıklaması - hafif
GlassButton(icon: "gear", ...) {}
    // .light() otomatik

// Önemli aksiyon - orta
Button("Refresh") {
    HapticEngine.shared.weatherRefresh() // medium
}

// Kritik uyarı - ağır
case .loaded(let state) where state.hasCriticalAlert:
    HapticEngine.shared.criticalAlert() // heavy + notification
```

---

## 🔍 Debug ve Profil

### Haptic Debug

```swift
#if DEBUG
extension HapticEngine {
    func debugLog(_ message: String) {
        print("[Haptic] \(message)")
    }
}
#endif
```

### Animasyon Profili

```swift
// Instruments için custom signpost
import OSLog

let animationLog = Logger(subsystem: "com.forewiz", category: "Animation")

func transition(to state: WeatherVisualState) {
    let signpostID = OSSignpostID(log: animationLog)
    animationLog.signpost(.begin, id: signpostID, "WeatherTransition")
    
    // ... animation logic
    
    animationLog.signpost(.end, id: signpostID, "WeatherTransition")
}
```

---

## 📋 Kontrol Listesi

Yeni mimariyi entegre ederken:

- [ ] `DependencyContainer`'ı güncelle
- [ ] `HapticEngine.shared.prepare()` launch'ta çağrılıyor
- [ ] `HomeViewStateFactory`'i ViewModel'e inject et
- [ ] Tüm butonlar `GlassButton` veya `microButton()` kullanıyor
- [ ] Kartlar `.microCardEntrance()` veya `.cardEntrance()` kullanıyor
- [ ] Arka plan `WeatherAwareBackground` kullanıyor
- [ ] Refresh `RefreshButton` ve `.microRefresh()` kullanıyor
- [ ] `WeatherStateTransitionManager` geçişleri yönetiyor
- [ ] Eski `HapticManager` çağrıları `HapticEngine`'e migrate edildi
- [ ] Unit testler yazıldı
- [ ] Accessibility audit yapıldı
- [ ] 120fps smooth scrolling doğrulandı

---

## 🆘 Sorun Giderme

### Haptic Engine Çalışmıyor

```swift
// Kontrol et
HapticEngine.shared.prepare() // Launch'ta çağrıldı mı?

// Debug
print("Haptic supported: \(UIImpactFeedbackGenerator().responds(to: #selector(UIImpactFeedbackGenerator.prepare())))"
```

### Animasyonlar Takılıyor

```swift
// Reduce Motion kontrolü
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Preview'da test
.viewerDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
```

### Lazy Stack Performans

```swift
// Identifier verilmemiş mi?
ForEach(forecasts, id: \.date) { ... } // ✅
ForEach(forecasts) { ... } // ❌ Eğer Identifiable değilse
```

---

**Son Güncelleme:** 13 Mayıs 2026  
**Versiyon:** 2.0 - Apple Design Award Standard
