//
//  HostingWindow.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import SwiftUI
import Combine

#if canImport(UIKit)
public  typealias Window = UIWindow
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

public struct HostingWindowKey: EnvironmentKey {
  public typealias Value = WeakAccessor<Window>? // needed for weak link
  public static let defaultValue: Self.Value = nil
}

public struct HostingWindowSizeKey: EnvironmentKey {
  public typealias Value = CGSize // needed for weak link
  public static let defaultValue: Self.Value = .zero
}

extension EnvironmentValues {
  public var hostingWindow: HostingWindowKey.Value {
    get {
      return self[HostingWindowKey.self]
    }
    set {
      self[HostingWindowKey.self] = newValue
    }
  }

  public var hostingWindowSize: HostingWindowSizeKey.Value {
    get {
      return self[HostingWindowSizeKey.self]
    }
    set {
      self[HostingWindowSizeKey.self] = newValue
    }
  }
}

public struct WindowInjector: ViewModifier {
  @State
  private(set) var window: WeakAccessor<Window>?
  @State
  private(set) var size: CGSize = .zero

  private let handler: (WeakAccessor<Window>?) -> ()
  private let sizeHandler: (CGSize) -> ()

  init(handler: @escaping (WeakAccessor<Window>?) -> (), sizeHandler: @escaping (CGSize) -> ()) {
    self.handler = handler
    self.sizeHandler = sizeHandler
  }

  init() {
    self.handler = { _ in }
    self.sizeHandler = { _ in }
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

extension View {
  public func windowInjector(
    handler: @escaping (WeakAccessor<Window>?) -> (), sizeHandler: @escaping (CGSize) -> ()
  ) -> some View {
    modifier(WindowInjector(handler: handler, sizeHandler: sizeHandler))
  }

  public func windowInjector() -> some View {
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
    self._window = window
    self._size = size
  }

  private func update(size: CGSize?) {
    if let size, self.size != size {
      self.size = size
    }
  }

  public func makeNSView(context: Context) -> ContainerView {
    let view = ContainerView()
    update(size: view.window?.frame.size)
    Task { @MainActor in
      self.window = WeakAccessor(value: view.window)
    }

    view.cancellable = NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)
      .receive(on: DispatchQueue.main)
      .map { _ in self.window?.value?.frame.size ?? .zero }
      .filter { $0 != .zero }
      .removeDuplicates()
      .sink { size in
        self.update(size: size)
      }

    return view
  }

  public func updateNSView(_ nsView: ContainerView, context: Context) {}

  public static func dismantleNSView(_ nsView: ContainerView, coordinator: ()) {
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
    self._window = window
    self._size = size
  }

  private func update(size: CGSize?) {
    if let size, self.size != size {
      self.size = size
    }
  }

  public func makeUIView(context: Context) -> ContainerView {
    let view = ContainerView()

    update(size: view.window?.bounds.size)
    Task { @MainActor in
      update(size: view.window?.bounds.size)
      self.window = WeakAccessor(value: view.window)
    }

    view.cancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
      .receive(on: DispatchQueue.main)
      .map { _ in self.window?.value?.bounds.size ?? .zero }
      .filter { $0 != .zero }
      .removeDuplicates()
      .sink { size in
        self.update(size: view.window?.bounds.size)
      }

    return view
  }

  public func updateUIView(_ nsView: ContainerView, context: Context) {}

  public static func dismantleUIView(_ uiView: ContainerView, coordinator: ()) {
    uiView.cancellable?.cancel()
  }
}
#else
#error("Unsupported platform")
#endif
