//
//  ShopDB.swift
//  RamenShopApp
//
//  Created by Koro Saka on 2020-11-23.
//  Copyright © 2020 Koro Saka. All rights reserved.
//

import Firebase
import FirebaseFirestore

struct FirebaseHelper {
    let firestore: Firestore
    let storage: Storage
    
    weak var delegate: FirebaseHelperDelegate?
    
    init() {
        firestore = Firestore.firestore()
        storage = Storage.storage()
    }
    
    func fetchShops() {
        var shops = [Shop]()
        firestore.collection("shop").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let location = data["location"] as! GeoPoint
                    let reviewInfo = data["review_info"] as! [String: Any]
                    let totalPoint = reviewInfo["total_point"] as? Int ?? 0
                    let count = reviewInfo["count"] as? Int ?? 0
                    shops.append(Shop(shopID: document.documentID,
                                      name: name,
                                      location: location,
                                      totalReview: totalPoint,
                                      reviewCount: count))
                }
                self.delegate?.completedFetchingShops(shops: shops)
            }
        }
    }
    
    func fetchLatestReviews(shopID: String) {
        // MARK: to judge to show "more" in LatestReviews in ShopDetailView (only 2reviews will be shown in ShopDetail)
        let numOfReview = 3
        fetchShopReviews(shopID: shopID, limitNum: numOfReview)
    }
    
    func fetchAllReview(shopID: String) {
        fetchShopReviews(shopID: shopID, limitNum: nil)
    }
    
    func fetchShopReviews(shopID: String, limitNum: Int?) {
        let reviewRef = createReviewRef(shopID: shopID)
        
        let completionHandler = { (querySnapshot: QuerySnapshot?, err: Error?) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let reviews = extractReviews(reviewQuery: querySnapshot!)
                self.delegate?.completedFetchingReviews(reviews: reviews)
            }
        }
        
        if limitNum != nil {
            reviewRef
                .order(by: "created_at", descending: true)
                .limit(to: limitNum!)
                .getDocuments(completion: completionHandler)
        } else {
            reviewRef
                .order(by: "created_at", descending: true)
                .getDocuments(completion: completionHandler)
        }
    }
    
    func fetchUserReview(shopID: String, userID: String) {
        let userReviewRef = createReviewRef(shopID: shopID)
            .whereField("user_id", isEqualTo: userID)
        
        userReviewRef.getDocuments { (querySnapshot, error) in
            if error != nil {
                return print("error happened in fetchUserReview !!")
            }
            for doc in querySnapshot!.documents {
                delegate?.completedFetchingUserReview(reviewID: doc.documentID,
                                                      imageCount: doc.data()["image_number"] as? Int ?? 0,
                                                      evaluation: doc.data()["evaluation"] as? Int ?? nil)
                return
            }
        }
    }
    
    func createReviewRef(shopID: String) -> CollectionReference {
        return firestore.collection("shop")
            .document(shopID)
            .collection("review")
    }
    
    func extractReviews(reviewQuery: QuerySnapshot) -> [Review] {
        var reviews = [Review]()
        for document in reviewQuery.documents {
            let data = document.data()
            let createdTimestamp = data["created_at"] as? Timestamp
            let review = Review(reviewID: document.documentID,
                                userID: data["user_id"] as? String ?? "",
                                evaluation: data["evaluation"] as? Int ?? 0,
                                comment: data["comment"] as? String ?? "",
                                imageCount: data["image_number"] as? Int ?? 0,
                                createdDate: createdTimestamp!.dateValue())
            reviews.append(review)
        }
        return reviews
    }
    
    func fetchUserProfile(userID: String) {
        let userRef = firestore.collection("user")
            .document(userID)
        
        userRef.getDocument { (document, error) in
            if error != nil {
                return print("error happened in fetchUserProfile !!")
            }
            var profile = Profile(userName: "unnamed", icon: nil)
            if let data = document?.data() {
                profile.userName = data["user_name"] as? String ?? "unnamed"
                let hasIcon = data["has_icon"] as? Bool ?? false
                if hasIcon {
                    fetchUserIcon(userID, profile)
                } else {
                    delegate?.completedFetchingProfile(profile: profile)
                }
            } else {
                delegate?.completedFetchingProfile(profile: profile)
                return
            }
        }
    }
    
    fileprivate func fetchUserIcon(_ userID: String, _ profile: Profile) {
        let iconStorageRef = storage.reference().child("user_icon/\(userID)")
        let completionHandler = { (result: StorageListResult, error: Error?) -> Void in
            // MARK: asynchronous
            if error != nil {
                delegate?.completedFetchingProfile(profile: profile)
                return print("error happened in fetchUserIcon !!")
            }
            let iconRef: StorageReference? = result.items[0]
            if iconRef != nil {
                iconRef!.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    // MARK: asynchronous
                    if let error = error {
                        print("Error getting data: \(error)")
                        delegate?.completedFetchingProfile(profile: profile)
                    } else {
                        let iconProfile = Profile(userName: profile.userName, icon: UIImage(data: data!))
                        delegate?.completedFetchingProfile(profile: iconProfile)
                    }
                }
            } else {
                delegate?.completedFetchingProfile(profile: profile)
                return
            }
        }
        
        iconStorageRef.list(withMaxResults: 1, completion: completionHandler)
    }
    
    func fetchPictureReviews(shopID: String, limit: Int?) {
        // MARK: TODO use createReviewRef(shopID: String)
        let reviewStoreRef =
            firestore.collection("shop")
            .document(shopID)
            .collection("review")
        var pictureReviewRef = reviewStoreRef.whereField("image_number", isGreaterThan: 0)
        // MARK: TODO .order(by: "created_at", descending: true)
        if let _limit = limit {
            pictureReviewRef = pictureReviewRef.limit(to: _limit)
        }
        pictureReviewRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.fetchImageFromReviewDocs(imageReviewsQS: querySnapshot!)
            }
        }
    }
    
    // MARK: to get images of a shop (used for ShopDetail)
    func fetchImageFromReviewDocs(imageReviewsQS: QuerySnapshot) {
        var totalPictures = [UIImage]()
        let totalImageReviewCount = imageReviewsQS.documents.count
        var readImageReviewCount = 0
        
        let completionHandler = { (pictures: [UIImage]) -> Void in
            totalPictures += pictures
            readImageReviewCount += 1
            // MARK: completed getting images of every review?
            if readImageReviewCount == totalImageReviewCount {
                self.delegate?.completedFetchingPictures(pictures: totalPictures)
            }
        }
        
        for reviewDoc in imageReviewsQS.documents {
            fetchReviewImage(id: reviewDoc.documentID, completion: completionHandler)
        }
    }
    
    // MARK: to get images of a review (used for ReviewDetail)
    func fetchImageFromReview(review: Review) {
        let completionHandler = { (pictures: [UIImage]) -> Void in
            self.delegate?.completedFetchingPictures(pictures: pictures)
        }
        fetchReviewImage(id: review.reviewID, completion: completionHandler)
    }
    
    private func fetchReviewImage(id reviewID: String, completion: @escaping ([UIImage]) -> Void) {
        var reviewImages = [UIImage]()
        let reviewStorageRef = storage.reference().child("review_picture/\(reviewID)")
        reviewStorageRef.listAll { (result, error) in
            // MARK: asynchronous
            if let error = error {
                print("Error getting data: \(error)")
            }
            let totalImageCount = result.items.count
            var readImageCount = 0
            for item in result.items {
                item.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    // MARK: asynchronous
                    if let error = error {
                        print("Error getting data: \(error)")
                    } else {
                        let image = UIImage(data: data!)
                        reviewImages.append(image!)
                    }
                    readImageCount += 1
                    // MARK: completed getting images of 1 review?
                    if readImageCount == totalImageCount {
                        completion(reviewImages)
                    }
                }
            }
        }
    }
    
    /**
     if there have been files which name is same already, putData() will overwrite the file.
     This is because these old files don't have to be deleted except when old pictures' count is learger than new pictures' one
     */
    func updateReviewPics(pics: [UIImage],
                          reviewID: String,
                          prePicCount: Int) {
        uploadReviewPics(pics, reviewID)
        deletePreviousReviewPics(pics.count, prePicCount, reviewID)
    }
    
    fileprivate func uploadReviewPics(_ pics: [UIImage],
                                      _ reviewID: String) {
        if pics.count == 0 {
            delegate?.completedUploadingReviewPics()
            return
        }
        
        var uploadCount = 0
        for picIndex in 0..<pics.count {
            guard let data: Data = pics[picIndex].jpegData(compressionQuality: 0.1) else { continue }
            createReviewPicRef(reviewID, picIndex)
                .putData(data, metadata: nil) { (metadata, error) in
                    if let _error = error {
                        print("Error uploadPictures: \(_error)")
                    }
                    uploadCount += 1
                    if uploadCount == pics.count {
                        delegate?.completedUploadingReviewPics()
                    }
                }
        }
    }
    
    fileprivate func deletePreviousReviewPics(_ newPicCount: Int,
                                              _ prePicCount: Int,
                                              _ reviewID: String) {
        if newPicCount >= prePicCount {
            delegate?.completedDeletingReviewPics()
            return
        }
        
        var deleteCount = 0
        let countToDelete = prePicCount - newPicCount
        for picIndex in newPicCount..<prePicCount {
            createReviewPicRef(reviewID, picIndex)
                .delete { error in
                    if let error = error {
                        print("Error on deleting: \(error)")
                    }
                    deleteCount += 1
                    if deleteCount == countToDelete {
                        delegate?.completedDeletingReviewPics()
                    }
                }
        }
    }
    
    fileprivate func createReviewPicRef(_ reviewID: String, _ index: Int) -> StorageReference {
        return storage.reference().child("review_picture/\(reviewID)/review_image_\(index).jpeg")
    }
    
    /**
     setData() will overwrite self previous review contents when it exists.
     when it doesn't, it will create a new document
     */
    func updateReview(shopID: String, review: Review) {
        let timeStamp: Timestamp = .init(date: review.createdDate)
        // MARK: TODO use createReviewRef(shopID: String)?
        let reviewRef = firestore
            .collection("shop")
            .document(shopID)
            .collection("review")
            .document(review.reviewID)
        reviewRef.setData([
            "user_id": review.userID,
            "evaluation": review.evaluation,
            "comment": review.comment,
            "image_number": review.imageCount,
            "created_at": timeStamp
        ]) { err in
            //MARK: without network, this call back never happen, but data is changed only on local db,,,,,,,
            delegate?.completedUpdatingReview(isSuccess: (err == nil))
        }
    }
    
    func updateShopEvaluation(shopID: String, newEva: Int, preEva: Int?, totalPoint: Int, reviewCount: Int) {
        let isFirstReview = preEva == nil
        let pulsEvaForTotal = isFirstReview ? newEva : (newEva - preEva!)
        let newTotalPoint = totalPoint + pulsEvaForTotal
        let newReviewCount = isFirstReview ? (reviewCount + 1) : reviewCount
        
        let shopRef = firestore.collection("shop").document(shopID)
        shopRef.updateData([
            "review_info": [ "total_point": newTotalPoint,
                             "count": newReviewCount ]
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            }
            delegate?.completedUpdatingShopEvaluation()
        }
    }
    
    func fetchShop(shopID: String) {
        let shopRef = firestore.collection("shop").document(shopID)
        shopRef.getDocument { (document, error) in
            if let _error = error {
                print("Error happen :\(_error)")
                return
            }
            guard let shopData = document?.data(),
                  let name = shopData["name"] as? String,
                  let location = shopData["location"] as? GeoPoint,
                  let reviewInfo =  shopData["review_info"] as? [String: Any],
                  let totalEvaluation = reviewInfo["total_point"] as? Int,
                  let reviewCount = reviewInfo["count"] as? Int
            else { return }
            
            let shop = Shop(shopID: shopID,
                            name: name,
                            location: location,
                            totalReview: totalEvaluation,
                            reviewCount: reviewCount)
            delegate?.completedFetchingShop(fetchedShopData: shop)
        }
    }
}

protocol FirebaseHelperDelegate: class {
    func completedFetchingShops(shops: [Shop])
    func completedFetchingReviews(reviews: [Review])
    func completedFetchingPictures(pictures: [UIImage])
    func completedFetchingProfile(profile: Profile)
    func completedFetchingUserReview(reviewID: String, imageCount: Int, evaluation: Int?)
    func completedUpdatingReview(isSuccess: Bool)
    func completedUploadingReviewPics()
    func completedDeletingReviewPics()
    func completedFetchingShop(fetchedShopData: Shop)
    func completedUpdatingShopEvaluation()
}

// MARK: default implements
extension FirebaseHelperDelegate {
    func completedFetchingShops(shops: [Shop]) {
        print("default implemented completedFetchingShop")
    }
    func completedFetchingReviews(reviews: [Review]) {
        print("default implemented completedFetchingReviews")
    }
    func completedFetchingPictures(pictures: [UIImage]) {
        print("default implemented completedFetchingPictures")
    }
    func completedFetchingProfile(profile: Profile) {
        print("default implemented completedFetchingProfile")
    }
    //MARK: TODO the arg should be Review ?
    func completedFetchingUserReview(reviewID: String, imageCount: Int, evaluation: Int?) {
        print("default implemented completedFetchingUserReview")
    }
    func completedUpdatingReview(isSuccess: Bool) {
        print("default implemented completedUploadingReview")
    }
    func completedUploadingReviewPics() {
        print("default implemented completedUploadingReviewPics")
    }
    func completedDeletingReviewPics() {
        print("default implemented completedDeletingReviewPics")
    }
    func completedFetchingShop(fetchedShopData: Shop) {
        print("default implemented completedFetchingShopEvaluation")
    }
    func completedUpdatingShopEvaluation() {
        print("default implemented completedUpdatingShopEvaluation")
    }
}

struct Shop {
    let shopID: String
    let name: String
    let location: GeoPoint
    let totalReview: Int
    let reviewCount: Int
    var aveEvaluation: Float {
        return calcAveEvaluation(totalReview, reviewCount)
    }
    
    func roundEvaluatione() -> String {
        if aveEvaluation == Float(0.0) {
            return "---"
        }
        return String(format: "%.1f", aveEvaluation)
    }
    
    func calcAveEvaluation(_ totalPoint: Int, _ reviewCount: Int) -> Float {
        if totalPoint == 0 || reviewCount == 0 {
            return Float(0.0)
        }
        return Float(totalPoint) / Float(reviewCount)
    }
}

struct Review {
    let reviewID: String
    let userID: String
    let evaluation: Int
    let comment: String
    let imageCount: Int
    let createdDate: Date
    
    func displayDate() -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy/MM/dd"
        return dateFormater.string(from: createdDate)
    }
}

struct Profile {
    var userName: String
    var icon: UIImage?
}
