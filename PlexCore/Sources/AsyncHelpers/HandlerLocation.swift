//
//  HandlerLocation.swift
//  
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

public struct HandlerLocation: Hashable, Sendable {
  let file: String
  let line: UInt
  let function: String
}
