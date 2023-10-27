//
//  StoredTask.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

struct StoredTask<IdentifierType: Sendable, ResultType: Sendable>: Sendable {
  let identifier: IdentifierType
  let task: TaskState<ResultType>
  let storeDate: Date
}
