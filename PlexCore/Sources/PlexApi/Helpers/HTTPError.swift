//
//  HTTPError.swift
//
//
//  Created by Tomas Harkema on 18/10/2023.
//

import Foundation

public enum HTTPError: Error {
  case noHttpResponse
  case unexpectedStatusCode(code: Int)

  public static func throwFor(urlResponse: URLResponse) throws {
    guard let httpRes = (urlResponse as? HTTPURLResponse) else {
      throw HTTPError.noHttpResponse
    }

    guard (200..<400).contains(httpRes.statusCode) else {
      throw HTTPError.unexpectedStatusCode(code: httpRes.statusCode)
    }
  }
}
