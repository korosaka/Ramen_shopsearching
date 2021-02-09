//
//  ProfileSettingView.swift
//  RamenShopApp
//
//  Created by Koro Saka on 2020-12-29.
//  Copyright © 2020 Koro Saka. All rights reserved.
//

import SwiftUI
import QGrid

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    var body: some View {
        ZStack {
            BackGroundView()
            ScrollView(.vertical) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 15)
                        IconProfile()
                        Spacer().frame(height: 10)
                        NameProfile()
                        Spacer().frame(height: 20)
                        FavoriteHeader()
                        FavoriteCollectionView(scrollable: false, favorites: viewModel.userFavorites)
                    }
                    .wideStyle()
                    
                    ProfileSetting()
                        .sidePadding(size: 10)
                }
            }
            
            if viewModel.isShowingProgress {
                CustomedProgress()
            }
        }
    }
}

struct IconProfile: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    var body: some View {
        VStack {
            viewModel
                .getIconImage()
                .iconLargeStyle()
        }
        .sheet(isPresented: $viewModel.isShowPhotoLibrary,
               content: { ImagePicker(delegate: viewModel) })
        .alert(isPresented: $viewModel.isShowPhotoPermissionDenied) {
            Alert(title: Text("This app has no permission"),
                  message: Text("You need to change setting"),
                  primaryButton: .default(Text("go to setting")) {
                    goToSetting()
                  },
                  secondaryButton: .cancel(Text("cancel")))
        }
    }
}

struct NameProfile: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.getUserName())
                .font(.largeTitle)
                .bold()
                .foregroundColor(.strongPink)
                .shadow(color: .black, radius: 2, x: 2, y: 2)
            if viewModel.isEditingName {
                Spacer().frame(height: 15)
                TextField("user name", text: $viewModel.newName)
                    .basicStyle()
                Spacer().frame(height: 15)
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.onClickChangeName()
                    }) {
                        Text("cancel")
                            .containingSymbol(symbol: "trash.fill",
                                              color: .strongRed,
                                              textFont: .title2,
                                              symbolFont: .title3)
                    }
                    Spacer()
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.isShowingAlert = true
                    }) {
                        Spacer().frame(width: 15)
                        Text("done").font(.title2).bold()
                        Spacer().frame(width: 5)
                        Image(systemName: "paperplane.fill").font(.title3)
                        Spacer().frame(width: 15)
                    }
                    .setEnabled(enabled: viewModel.isNameEdited,
                                defaultColor: .strongPink,
                                padding: 10,
                                radius: 20)
                    Spacer()
                }
            }
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            switch viewModel.activeAlertForName {
            case .confirmation:
                return Alert(title: Text("Confirmation"),
                             message: Text("Change name?"),
                             primaryButton: .default(Text("Yes")) {
                                viewModel.updateUserName()
                             },
                             secondaryButton: .cancel(Text("cancel")))
            case .completion:
                return Alert(title: Text("Success"),
                             message: Text("Profile has been updated!"),
                             dismissButton: .default(Text("OK")) {
                                viewModel.resetAlertData()
                             })
            case .error:
                return Alert(title: Text("Failed"),
                             message: Text("Updating profile was failed"),
                             dismissButton: .default(Text("OK")){
                                viewModel.resetAlertData()
                             })
            }
        }
    }
}

struct ProfileSetting: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 15)
            HStack {
                Spacer()
                Button(action: {
                    viewModel.isShowingMenu.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                        .circleSymbol(font: .title3,
                                      fore: .gray,
                                      back: .white)
                }
            }
            
            if viewModel.isShowingMenu {
                Spacer().frame(height: 10)
                HStack {
                    Spacer()
                    ProfileSettingMenu()
                }
            }
        }
    }
}

struct ProfileSettingMenu: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 15)
            Button(action: {
                viewModel.checkPhotoPermission()
                viewModel.isShowingMenu = false
            }) {
                Text("change icon")
            }
            Spacer().frame(height: 25)
            Button(action: {
                viewModel.onClickChangeName()
                viewModel.isShowingMenu = false
            }) {
                Text("change name")
            }
            Spacer().frame(height: 25)
            Button(action: {
                viewModel.isShowingMenu = false
            }) {
                Text("close")
            }
            Spacer().frame(height: 15)
        }
        .sidePadding(size: 5)
        .background(Color.superWhitePasteGreen)
        .cornerRadius(10)
    }
}

struct FavoriteHeader: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.title2)
            .foregroundColor(.strongPink)
            .upDownPadding(size: 5)
            .wideStyle()
            .background(Color.superWhitePasteGreen)
    }
    
}

struct FavoriteCollectionView: View {
    let scrollable: Bool
    let favorites: [FavoriteShopInfo]
    let pictureSize: CGFloat = UIScreen.main.bounds.size.width / 2
    let space: CGFloat = 0.0
    let padding: CGFloat = 0.0
    var row: Int {
        return (favorites.count + 1) / 2
    }
    var frameHieght: CGFloat? {
        if scrollable {
            return .none
        } else {
            return pictureSize * CGFloat(row)
        }
    }
    
    var body: some View {
        if favorites.count == 0 {
            VStack {
                Text("No Picture")
            }
        } else {
            QGrid(self.favorites,
                  columns: 2,
                  vSpacing: space,
                  hSpacing: space,
                  vPadding: padding,
                  hPadding: padding,
                  isScrollable: scrollable,
                  showScrollIndicators: scrollable
            ) { shopInfo in
                FavoriteCell(shop: shopInfo, size: pictureSize)
            }
            .frame(height: frameHieght)
        }
        
    }
    
}

struct FavoriteCell: View {
    let shop: FavoriteShopInfo
    let size: CGFloat
    
    var body: some View {
        
        VStack {
            if let image = shop.shopTopImage {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .border(Color.green)
            } else {
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .border(Color.green)
            }
            Text(shop.shopName ?? "")
        }
        
    }
}

struct FavoriteShopInfo: Identifiable {
    let id: String //MARK: ShopID
    var shopName: String?
    var shopTopImage: Image?
}
