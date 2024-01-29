//
//  AllTagsContext.swift
//  
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct AllTagsContext: Encodable {
  let title = WebsiteView.allTags.title
  let userLoggedIn: Bool
  let tags: [Tag]
}
