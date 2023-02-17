//
//  User.swift
//  SocialMedia
//
//  Created by Aleksandr Pavlov on 14.02.23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable,Codable {
    @DocumentID var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingsKeys: CodingKey {
        case id
        case username
        case userBio
        case userBioLink
        case useriUID
        case userEmail
        case userProfileURL
    }
    
    
}

