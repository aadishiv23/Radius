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
    //@Binding var showView: Bool
    //@Binding var locationToAdd: CLLocationCoordinate2D?
    
    @StateObject var viewModel: AddressEntryViewModel = AddressEntryViewModel()
    @FocusState private var isFocusedTextField: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Type address", text: $viewModel.searchableText)
                    .padding()
                    .autocorrectionDisabled()
                    .focused($isFocusedTextField)
                    .font(.title)
                    .onReceive(
                        viewModel.$searchableText.debounce(
                            for: .seconds(1),
                            scheduler: DispatchQueue.main
                        )
                    ) {
                        viewModel.searchAddress($0)
                    }
                    .background(Color.init(uiColor: .systemBackground))
//                    .overlay {
//                        ClearButton(text: $viewModel.searchableText)
//                            .padding(.trailing)
//                            .padding(.top, 8)
//                    }
                    .onAppear {
                        isFocusedTextField = true
                    }
                
                List(self.viewModel.results) { address in
                        AddressRow(address: address)
                            .listRowBackground(backgroundColor)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    var backgroundColor: Color = Color.init(uiColor: .systemGray6)
}


struct AddressRow: View {
    
    let address: AddressResult
    
    var body: some View {
        NavigationLink {
            AddressEntryMapView(address: address)
        } label: {
            VStack(alignment: .leading) {
                Text(address.title)
                Text(address.subtitle)
                    .font(.caption)
            }
        }
        .padding(.bottom, 2)
    }
}

struct AddressEntryMapView: View {
    
    @StateObject private var viewModel = AddressEntryMapViewModel()

    private let address: AddressResult
    
    init(address: AddressResult) {
        self.address = address
    }
    
    var body: some View {
        Map(
            coordinateRegion: $viewModel.region,
            annotationItems: viewModel.annotationItems,
            annotationContent: { item in
                MapMarker(coordinate: item.coordinate)
            }
        )
        .onAppear {
            self.viewModel.getPlace(from: address)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
