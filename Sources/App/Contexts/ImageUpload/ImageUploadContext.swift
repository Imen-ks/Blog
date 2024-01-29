//
//  File.swift
//  
//
//  Created by Imen Ksouri on 26/01/2024.
//

import Foundation

struct ImageUploadContext: Encodable {
    let title: String
    let pictureType: String
    let reference: String
    let currentImage: String?
    let userLoggedIn: Bool
    let acronymId: String?
}
