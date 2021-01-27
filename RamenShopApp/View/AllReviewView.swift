//
//  AllReviewView.swift
//  RamenShopApp
//
//  Created by Koro Saka on 2020-12-03.
//  Copyright © 2020 Koro Saka. All rights reserved.
//

import SwiftUI

struct AllReviewView: View {
    
    @ObservedObject var viewModel: AllReviewViewModel
    
    var body: some View {
        ZStack {
            BackGroundView()
            VStack(spacing: 0) {
                CustomNavigationBar(additionalAction: nil)
                Text("All Review")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                    .padding(3)
                List {
                    ForEach(viewModel.reviews, id: \.reviewID) { review in
                        Button(action: {
                            viewModel.switchShowDetail(reviewID: review.reviewID)
                        }) {
                            if viewModel.showDetailDic[review.reviewID] ?? false {
                                ReviewDetailView(viewModel: .init(review: review))
                            } else {
                                ReviewHeadline(viewModel: .init(review: review))
                            }
                        }
                    }
                    .listRowBackground(Color.superWhitePasteGreen)
                }
                .cornerRadius(15)
                .padding(5)
            }
            if viewModel.isShowingProgress {
                CustomedProgress()
            }
        }
        .navigationBarHidden(true)
        .onAppear() {
            viewModel.fetchAllReview()
        }
    }
}
