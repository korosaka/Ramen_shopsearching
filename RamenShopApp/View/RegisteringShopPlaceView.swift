//
//  RegisteringShopPlaceView.swift
//  RamenShopApp
//
//  Created by Koro Saka on 2021-01-02.
//  Copyright © 2021 Koro Saka. All rights reserved.
//

import SwiftUI

struct RegisteringShopPlaceView: View {
    @ObservedObject var viewModel: RegisteringShopViewModel
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(additionalAction: nil)
            VStack(spacing: 0) {
                Text(viewModel.shopName)
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
                HStack {
                    Spacer()
                    Text("Put the Ramen Mark on ths shop place")
                        .foregroundColor(.yellow)
                    Spacer()
                }
                Text("Set shop's place on the center of this map")
                    .foregroundColor(.white)
            }
            .background(Color.blue)
            ZStack {
                GoogleMapView(registeringShopVM: viewModel)
                CenterMarker()
            }
            .padding(5)
            .background(Color.blue)
            Button(action: {
                viewModel.isShowAlert = true
            }) {
                HStack {
                    Spacer()
                    Text("I've selected shop's place")
                    Spacer()
                }
            }
            .basicStyle(foreColor: .white, backColor: .red, padding: 20, radius: 10).padding(10)
            .alert(isPresented: $viewModel.isShowAlert) {
                if (viewModel.location == nil) {
                    return Alert(title: Text("Shop info is insufficient"),
                                 message: Text("location data was not got well"),
                                 dismissButton: .default(Text("OK")){
                                    //MARK; TODO
                                 })
                }
                if (!viewModel.isZoomedEnough) {
                    return Alert(title: Text("Location is abstract"),
                                 message: Text("you must zoom up this map more!"),
                                 dismissButton: .default(Text("OK")){
                                    //MARK; TODO
                                 })
                }
                switch viewModel.activeAlertForName {
                case .confirmation:
                    return Alert(title: Text("Confirmation"),
                                 message: Text("Are you sure to send this request?"),
                                 primaryButton: .default(Text("Yes")) {
                                    //MARK; TODO
                                 },
                                 secondaryButton: .cancel(Text("cancel")))
                case .completion:
                    return Alert(title: Text("Success"),
                                 message: Text("Your request has been sent!"),
                                 dismissButton: .default(Text("OK")) {
                                    //MARK; TODO
                                 })
                case .error:
                    return Alert(title: Text("Failed"),
                                 message: Text("Updating request was failed"),
                                 dismissButton: .default(Text("OK")){
                                    //MARK; TODO
                                 })
                }
            }
        }
        .navigationBarHidden(true)
    }
    
}

struct CenterMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                Image("shop_icon")
                    .resizable()
                    .frame(width: 25.0, height: 25.0)
                Spacer()
            }
            Spacer()
        }
    }
}
