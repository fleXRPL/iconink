import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit

// System framework type aliases
/// Cross-platform image type (UIImage on iOS/iPadOS)
public typealias PlatformImage = UIImage
/// Cross-platform color type (UIColor on iOS/iPadOS)
public typealias PlatformColor = UIColor
/// Cross-platform font type (UIFont on iOS/iPadOS)
public typealias PlatformFont = UIFont
/// Cross-platform bezier path type (UIBezierPath on iOS/iPadOS)
public typealias PlatformBezierPath = UIBezierPath
/// Cross-platform view controller type (UIViewController on iOS/iPadOS)
public typealias PlatformViewController = UIViewController
/// Cross-platform view type (UIView on iOS/iPadOS)
public typealias PlatformView = UIView
/// Cross-platform screen type (UIScreen on iOS/iPadOS)
public typealias PlatformScreen = UIScreen
/// Cross-platform application type (UIApplication on iOS/iPadOS)
public typealias PlatformApplication = UIApplication
/// Cross-platform haptic feedback generator type (UIImpactFeedbackGenerator on iOS/iPadOS)
public typealias PlatformFeedbackGenerator = UIImpactFeedbackGenerator

/// SwiftUI wrapper for UIViewControllerRepresentable that works across platforms
public struct PlatformViewControllerRepresentable: UIViewControllerRepresentable {
    let makeUIViewController: (Context) -> UIViewController
    let updateUIViewController: (UIViewController, Context) -> Void
    
    /// Initializes a new platform view controller representable
    /// - Parameters:
    ///   - makeUIViewController: Closure to create the view controller
    ///   - updateUIViewController: Closure to update the view controller
    public init(
        makeUIViewController: @escaping (Context) -> UIViewController,
        updateUIViewController: @escaping (UIViewController, Context) -> Void = { _, _ in }
    ) {
        self.makeUIViewController = makeUIViewController
        self.updateUIViewController = updateUIViewController
    }
    
    /// Creates the view controller object and configures its initial state
    /// - Parameter context: The context structure containing information about the current state of the system
    /// - Returns: The view controller configured with the provided closure
    public func makeUIViewController(context: Context) -> UIViewController {
        makeUIViewController(context)
    }
    
    /// Updates the state of the specified view controller with new information
    /// - Parameters:
    ///   - uiViewController: The view controller to update
    ///   - context: The context structure containing information about the current state of the system
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        updateUIViewController(uiViewController, context)
    }
}

/// SwiftUI wrapper for UIViewRepresentable that works across platforms
public struct PlatformViewRepresentable: UIViewRepresentable {
    let makeUIView: (Context) -> UIView
    let updateUIView: (UIView, Context) -> Void
    
    /// Initializes a new platform view representable
    /// - Parameters:
    ///   - makeUIView: Closure to create the view
    ///   - updateUIView: Closure to update the view
    public init(
        makeUIView: @escaping (Context) -> UIView,
        updateUIView: @escaping (UIView, Context) -> Void = { _, _ in }
    ) {
        self.makeUIView = makeUIView
        self.updateUIView = updateUIView
    }
    
    /// Creates the view object and configures its initial state
    /// - Parameter context: The context structure containing information about the current state of the system
    /// - Returns: The view configured with the provided closure
    public func makeUIView(context: Context) -> UIView {
        makeUIView(context)
    }
    
    /// Updates the state of the specified view with new information
    /// - Parameters:
    ///   - uiView: The view to update
    ///   - context: The context structure containing information about the current state of the system
    public func updateUIView(_ uiView: UIView, context: Context) {
        updateUIView(uiView, context)
    }
}

// Platform specific methods
/// Opens a URL using the system's default handler
/// - Parameter url: The URL to open
public func openURL(_ url: URL) {
    UIApplication.shared.open(url)
}

/// Gets the bounds of the main screen
/// - Returns: A CGRect representing the screen bounds
public func getScreenBounds() -> CGRect {
    UIScreen.main.bounds
}

/// Creates a haptic feedback generator
/// - Parameter style: The feedback style to use
/// - Returns: A configured feedback generator
public func createFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> PlatformFeedbackGenerator {
    UIImpactFeedbackGenerator(style: style)
}

/// Draws text in a specified rectangle with given attributes
/// - Parameters:
///   - text: The text to draw
///   - rect: The rectangle in which to draw the text
///   - attributes: The attributes to apply to the text
public func drawText(_ text: String, in rect: CGRect, withAttributes attributes: [NSAttributedString.Key: Any]) {
    text.draw(in: rect, withAttributes: attributes)
}

#else
import AppKit

// System framework type aliases for macOS
/// Cross-platform image type (NSImage on macOS)
public typealias PlatformImage = NSImage
/// Cross-platform color type (NSColor on macOS)
public typealias PlatformColor = NSColor
/// Cross-platform font type (NSFont on macOS)
public typealias PlatformFont = NSFont
/// Cross-platform bezier path type (NSBezierPath on macOS)
public typealias PlatformBezierPath = NSBezierPath
/// Cross-platform view controller type (NSViewController on macOS)
public typealias PlatformViewController = NSViewController
/// Cross-platform view type (NSView on macOS)
public typealias PlatformView = NSView
/// Cross-platform screen type (NSScreen on macOS)
public typealias PlatformScreen = NSScreen
/// Cross-platform application type (NSApplication on macOS)
public typealias PlatformApplication = NSApplication
/// Cross-platform haptic feedback generator type (Any on macOS as direct equivalent doesn't exist)
public typealias PlatformFeedbackGenerator = Any

/// SwiftUI wrapper for NSViewControllerRepresentable that works across platforms
public struct PlatformViewControllerRepresentable: NSViewControllerRepresentable {
    let makeNSViewController: (Context) -> NSViewController
    let updateNSViewController: (NSViewController, Context) -> Void
    
    /// Initializes a new platform view controller representable
    /// - Parameters:
    ///   - makeNSViewController: Closure to create the view controller
    ///   - updateNSViewController: Closure to update the view controller
    public init(
        makeNSViewController: @escaping (Context) -> NSViewController,
        updateNSViewController: @escaping (NSViewController, Context) -> Void = { _, _ in }
    ) {
        self.makeNSViewController = makeNSViewController
        self.updateNSViewController = updateNSViewController
    }
    
    /// Creates the view controller object and configures its initial state
    /// - Parameter context: The context structure containing information about the current state of the system
    /// - Returns: The view controller configured with the provided closure
    public func makeNSViewController(context: Context) -> NSViewController {
        makeNSViewController(context)
    }
    
    /// Updates the state of the specified view controller with new information
    /// - Parameters:
    ///   - nsViewController: The view controller to update
    ///   - context: The context structure containing information about the current state of the system
    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        updateNSViewController(nsViewController, context)
    }
}

/// SwiftUI wrapper for NSViewRepresentable that works across platforms
public struct PlatformViewRepresentable: NSViewRepresentable {
    let makeNSView: (Context) -> NSView
    let updateNSView: (NSView, Context) -> Void
    
    /// Initializes a new platform view representable
    /// - Parameters:
    ///   - makeNSView: Closure to create the view
    ///   - updateNSView: Closure to update the view
    public init(
        makeNSView: @escaping (Context) -> NSView,
        updateNSView: @escaping (NSView, Context) -> Void = { _, _ in }
    ) {
        self.makeNSView = makeNSView
        self.updateNSView = updateNSView
    }
    
    /// Creates the view object and configures its initial state
    /// - Parameter context: The context structure containing information about the current state of the system
    /// - Returns: The view configured with the provided closure
    public func makeNSView(context: Context) -> NSView {
        makeNSView(context)
    }
    
    /// Updates the state of the specified view with new information
    /// - Parameters:
    ///   - nsView: The view to update
    ///   - context: The context structure containing information about the current state of the system
    public func updateNSView(_ nsView: NSView, context: Context) {
        updateNSView(nsView, context)
    }
}

// Platform specific methods for macOS
/// Opens a URL using the system's default handler
/// - Parameter url: The URL to open
public func openURL(_ url: URL) {
    NSWorkspace.shared.open(url)
}

/// Gets the bounds of the main screen
/// - Returns: A CGRect representing the screen bounds
public func getScreenBounds() -> CGRect {
    guard let screen = NSScreen.main else { return .zero }
    return screen.frame
}

/// Creates a feedback generator (limited functionality on macOS)
/// - Parameter style: The feedback style to use (ignored on macOS)
/// - Returns: A placeholder feedback generator (NSSound on macOS)
public func createFeedback(style: Int = 0) -> PlatformFeedbackGenerator {
    // No direct equivalent on macOS
    return NSSound.self
}

/// Draws text in a specified rectangle with given attributes
/// - Parameters:
///   - text: The text to draw
///   - rect: The rectangle in which to draw the text
///   - attributes: The attributes to apply to the text
public func drawText(_ text: String, in rect: CGRect, withAttributes attributes: [NSAttributedString.Key: Any]) {
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    attributedString.draw(in: rect)
}

#endif

// Platform-agnostic helpers
extension Color {
    /// Creates a Color that adapts between light and dark mode automatically
    /// - Parameters:
    ///   - light: The color to use in light mode
    ///   - dark: The color to use in dark mode
    /// - Returns: An adaptive Color that changes based on the system appearance
    public static func adaptivePlatformColor(light: PlatformColor, dark: PlatformColor) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        })
        #else
        return Color(nsColor: NSApp.effectiveAppearance.isDarkMode ? dark : light)
        #endif
    }
}

#if !canImport(UIKit)
extension NSAppearance {
    /// Determines if the current appearance is a dark mode variant
    var isDarkMode: Bool {
        guard let name = self.name else { return false }
        return name == .darkAqua || 
               name == .vibrantDark || 
               name == .accessibilityHighContrastDarkAqua || 
               name == .accessibilityHighContrastVibrantDark
    }
}
#endif 
