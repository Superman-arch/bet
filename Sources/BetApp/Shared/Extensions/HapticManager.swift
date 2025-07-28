#if os(iOS)
import UIKit
#endif

struct HapticManager {
    #if os(iOS)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    #else
    static func impact(_ style: String = "medium") {
        // Haptic feedback is not available on macOS
    }
    
    static func notification(_ type: String) {
        // Haptic feedback is not available on macOS
    }
    
    static func selection() {
        // Haptic feedback is not available on macOS
    }
    #endif
    
    static func success() {
        #if os(iOS)
        notification(.success)
        #else
        notification("success")
        #endif
    }
    
    static func error() {
        #if os(iOS)
        notification(.error)
        #else
        notification("error")
        #endif
    }
    
    static func warning() {
        #if os(iOS)
        notification(.warning)
        #else
        notification("warning")
        #endif
    }
}