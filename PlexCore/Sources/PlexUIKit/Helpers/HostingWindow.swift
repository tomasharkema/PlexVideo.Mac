//
//  HostingWindow.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import Combine
import SwiftUI
import SwiftUIMacros

#if canImport(UIKit)
public typealias Window = UIWindow
#elseif canImport(AppKit)
public typealias Window = NSWindow
#else
#error("Unsupported platform")
#endif

public class WeakAccessor<ValueType: AnyObject & Equatable>: Equatable {
  public internal(set) weak var value: ValueType?

  init(value: ValueType?) {
    self.value = value
  }

  public static func == (lhs: WeakAccessor<ValueType>, rhs: WeakAccessor<ValueType>) -> Bool {
    lhs.value == rhs.value
  }
}

// public struct HostingWindowKey: EnvironmentKey {
//  public typealias Value = WeakAccessor<Window>? // needed for weak link
//  public static let defaultValue: Self.Value = nil
// }
//
// public struct HostingWindowSizeKey: EnvironmentKey {
//  public typealias Value = CGSize // needed for weak link
//  public static let defaultValue: Self.Value = .zero
// }

@EnvironmentStorage
extension EnvironmentValues {
  var hostingWindow: WeakAccessor<Window>?
  var hostingWindowSize: CGSize = .zero
}

// public extension EnvironmentValues {
//  var hostingWindow: HostingWindowKey.Value {
//    get {
//      self[HostingWindowKey.self]
//    }
//    set {
//      self[HostingWindowKey.self] = newValue
//    }
//  }
//
//  var hostingWindowSize: HostingWindowSizeKey.Value {
//    get {
//      self[HostingWindowSizeKey.self]
//    }
//    set {
//      self[HostingWindowSizeKey.self] = newValue
//    }
//  }
// }

public struct WindowInjector: ViewModifier {
  @State
  private(set) var window: WeakAccessor<Window>?
  @State
  private(set) var size: CGSize = .zero

  private let handler: (WeakAccessor<Window>?) -> Void
  private let sizeHandler: (CGSize) -> Void

  init(handler: @escaping (WeakAccessor<Window>?) -> Void,
       sizeHandler: @escaping (CGSize) -> Void)
  {
    self.handler = handler
    self.sizeHandler = sizeHandler
  }

  init() {
    handler = { _ in }
    sizeHandler = { _ in }
  }

  public func body(content: Content) -> some View {
    content
      .background {
        WindowAccessor(window: $window, size: $size)
      }
      .onChange(of: window) {
        handler(window)
      }
      .onChange(of: size) {
        sizeHandler(size)
      }
      .environment(\.hostingWindow, window)
      .environment(\.hostingWindowSize, size)
  }
}

public extension View {
  func windowInjector(
    handler: @escaping (WeakAccessor<Window>?) -> Void, sizeHandler: @escaping (CGSize) -> Void
  ) -> some View {
    modifier(WindowInjector(handler: handler, sizeHandler: sizeHandler))
  }

  func windowInjector() -> some View {
    modifier(WindowInjector())
  }
}

#if canImport(AppKit)

public final class ContainerView: NSView {
  var cancellable: AnyCancellable?
}

public struct WindowAccessor: NSViewRepresentable {
  @Binding
  private var window: WeakAccessor<NSWindow>?

  @Binding
  private var size: CGSize

  init(window: Binding<WeakAccessor<NSWindow>?>, size: Binding<CGSize>) {
    _window = window
    _size = size
  }

  private func update(size: CGSize?) {
    if let size, self.size != size {
      self.size = size
    }
  }

  public func makeNSView(context _: Context) -> ContainerView {
    let view = ContainerView()
    update(size: view.window?.frame.size)
    Task { @MainActor in
      window = WeakAccessor(value: view.window)
    }

    view.cancellable = NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)
      .receive(on: DispatchQueue.main)
      .map { _ in window?.value?.frame.size ?? .zero }
      .filter { $0 != .zero }
      .removeDuplicates()
      .sink { size in
        update(size: size)
      }

    return view
  }

  public func updateNSView(_: ContainerView, context _: Context) {}

  public static func dismantleNSView(_ nsView: ContainerView, coordinator _: ()) {
    nsView.cancellable?.cancel()
  }
}

#elseif canImport(UIKit)

public final class ContainerView: UIView {
  var cancellable: AnyCancellable?
}

public struct WindowAccessor: UIViewRepresentable {
  @Binding
  private var window: WeakAccessor<UIWindow>?

  @Binding
  private var size: CGSize

  init(window: Binding<WeakAccessor<UIWindow>?>, size: Binding<CGSize>) {
    _window = window
    _size = size
  }

  private func update(size: CGSize?) {
    if let size, self.size != size {
      self.size = size
    }
  }

  public func makeUIView(context _: Context) -> ContainerView {
    let view = ContainerView()

    update(size: view.window?.bounds.size)
    Task { @MainActor in
      update(size: view.window?.bounds.size)
      window = WeakAccessor(value: view.window)
    }

    view.cancellable = NotificationCenter.default
      .publisher(for: UIDevice.orientationDidChangeNotification)
      .receive(on: DispatchQueue.main)
      .map { _ in window?.value?.bounds.size ?? .zero }
      .filter { $0 != .zero }
      .removeDuplicates()
      .sink { _ in
        update(size: view.window?.bounds.size)
      }

    return view
  }

  public func updateUIView(_: ContainerView, context _: Context) {}

  public static func dismantleUIView(_ uiView: ContainerView, coordinator _: ()) {
    uiView.cancellable?.cancel()
  }
}
#else
#error("Unsupported platform")
#endif
