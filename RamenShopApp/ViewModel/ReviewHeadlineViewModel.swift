//
//  ReviewHeadlineViewModel.swift
//  RamenShopApp
//
//  Created by Koro Saka on 2020-12-19.
//  Copyright © 2020 Koro Saka. All rights reserved.
//

import Foundation
class ReviewHeadlineViewModel: ObservableObject {
    let review: Review
    var db: DatabaseHelper
    @Published var userProfile: Profile
    
    init(review: Review) {
        self.review = review
        userProfile = Profile()
        db = .init()
        db.delegate = self
        fetchProfile()
    }
    
    func fetchProfile() {
        db.fetchUserProfile(userID: review.userID)
    }
}

extension ReviewHeadlineViewModel: FirebaseHelperDelegate {
    func completedFetchingProfile(profile: Profile?) {
        guard let _profile = profile else { return }
        userProfile = _profile
    }
}
