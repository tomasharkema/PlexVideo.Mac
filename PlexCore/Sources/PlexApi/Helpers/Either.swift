//
//  Either.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation
import SwiftMacros

@AddAssociatedValueVariable
public enum Either<LeftType, RightType> {
  case left(LeftType)
  case right(RightType)
}

extension Either: Sendable where LeftType: Sendable, RightType: Sendable {}
extension Either: Hashable where LeftType: Hashable, RightType: Hashable {}
extension Either: Equatable where LeftType: Equatable, RightType: Equatable {}
