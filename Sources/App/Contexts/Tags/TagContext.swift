//
//  TagContext.swift
//  
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct TagContext: Encodable {
  let title: String
  let userLoggedIn: Bool
  let tag: Tag
  let articles: [Article]
}
