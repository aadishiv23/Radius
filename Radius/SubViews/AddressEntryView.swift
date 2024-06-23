//
//  AddressEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

struct AddressEntryView: View {
    @Binding var isPresenting: Bool
    @Binding var newZoneLocation: CLLocationCoordinate2D?
    @Binding var zoneName: String
    @Binding var zoneRadius: Double
    @StateObject private var viewModel = AddressEntryViewModel()
    @State private var selectedAddress: AddressResult?
    @FocusState private var isFocusedTextField: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search for an address", text: $viewModel.searchableText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isFocusedTextField)
                .autocorrectionDisabled()
                .onReceive(
                    viewModel.$searchableText.debounce(
                        for: .seconds(1),
                        scheduler: DispatchQueue.main
                    )
                ) {
                    viewModel.searchAddress($0)
                }
            
            if let selectedAddress = selectedAddress {
                AddressMapView(address: selectedAddress) { coordinate in
                    self.newZoneLocation = coordinate
                    self.isPresenting = false
                }
            } else {
                ZStack {
                    List(viewModel.results) { address in
                        AddressRow(address: address)
                            .onTapGesture {
                                selectedAddress = address
                            }
                    }
                    .listStyle(.plain)
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                            .foregroundStyle(Color.purple)
                    }
                }
            }
        }
        .onAppear {
            isFocusedTextField = true
        }
    }
}


//struct AddressRow: View {
//    
//    let address: AddressResult
//    
//    var body: some View {
//        NavigationLink {
//            AddressEntryMapView(address: address)
//        } label: {
//            VStack(alignment: .leading) {
//                Text(address.title)
//                Text(address.subtitle)
//                    .font(.caption)
//            }
//        }
//        .padding(.bottom, 2)
//    }
//}

struct AddressRow: View {
    let address: AddressResult
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(address.title)
            Text(address.subtitle)
                .font(.caption)
        }
        .padding(.bottom, 2)
    }
}

//struct AddressEntryMapView: View {
//    
//    @StateObject private var viewModel = AddressEntryMapViewModel()
//
//    private let address: AddressResult
//    
//    init(address: AddressResult) {
//        self.address = address
//    }
//    
//    var body: some View {
//        Map(
//            coordinateRegion: $viewModel.region,
//            annotationItems: viewModel.annotationItems,
//            annotationContent: { item in
//                MapMarker(coordinate: item.coordinate)
//            }
//        )
//        .onAppear {
//            self.viewModel.getPlace(from: address)
//        }
//        .edgesIgnoringSafeArea(.bottom)
//    }
//}

struct AddressMapView: View {
    let address: AddressResult
    let onSelect: (CLLocationCoordinate2D) -> Void
    @StateObject private var viewModel = AddressEntryMapViewModel()
    
    var body: some View {
        Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.annotationItems) { item in
            MapMarker(coordinate: item.coordinate)
        }
        .overlay(alignment: .bottom) {
            Button("Select This Location") {
                if let coordinate = viewModel.annotationItems.first?.coordinate {
                    onSelect(coordinate)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom)
        }
        .onAppear {
            viewModel.getPlace(from: address)
        }
    }
}
