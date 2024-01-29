//
//  IndexContext.swift
//
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct IndexContext: Encodable {
    let title = WebsiteView.index.title
    let articles: [Article]
    let userLoggedIn: Bool
    let showCookieMessage: Bool
}
