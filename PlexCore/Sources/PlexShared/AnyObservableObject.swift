//
//  AnyObservableObject.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import Combine

public protocol AnyObservableObject: AnyObject {
  var objectWillChange: ObservableObjectPublisher { get }
}
