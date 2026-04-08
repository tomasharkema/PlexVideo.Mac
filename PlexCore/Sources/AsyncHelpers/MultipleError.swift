import Foundation
import NonEmpty
import StringsBuilder
import SwiftStacktrace

public struct MultipleError: Error {
  public private(set) var errors: NonEmptyArray<StacktraceError>

  package init(_ error: StacktraceError) {
    errors = .init(error)
  }

  package init(_ error: any Error) {
    if let error = error as? StacktraceError {
      self.init(error)
    } else {
      assertionFailure("Please give a StacktraceError")
      self.init(StacktraceError(error))
    }
  }

  package mutating func append(_ error: StacktraceError) {
    errors.append(error)
  }

  @StringBuilder
  private var smallDescription: some StringConvertible {
    Appending {
      Partial("Multiple errors:")
      List(separator: ", ") {
        for descripion in errors {
          Partial("\(descripion.localizedDescription)")
        }
      }
    }
  }
}

extension MultipleError: LocalizedError {
  public var errorDescription: String? {
    smallDescription.string
  }
}

extension MultipleError: CustomStringConvertible {
  public var description: String {
    assertionFailure()
    return ""
  }
}

extension MultipleError: CustomDebugStringConvertible {
  public var debugDescription: String {
    debugDescriptionResult.string
  }

  @StringBuilder
  private var debugDescriptionResult: some StringConvertible {
    Empty()
    "vvv"
    "MultipleError:"
    Empty()
    "Got the following errors:"
    Empty()
    for (index, error) in errors.enumerated() {
      Appending {
        "\(index):"
        "\(type(of: error))"
      }
      Empty()
      Paragraph {
        Indented {
          "\(error.debugDescription)"
        }
      }
      Empty()
      Empty()
    }
    "^^^"
  }
}
