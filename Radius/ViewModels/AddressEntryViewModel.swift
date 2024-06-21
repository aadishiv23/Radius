//
//  AddressEntryViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/20/24.
//

import Foundation
import MapKit

class AddressEntryViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var results: Array<AddressResult> = []
    @Published var searchableText = ""
    
    // mklcoalsearch compeltere is a utility object for generating list of commpletion string based on partial string provided by user
    private lazy var localSearchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.delegate = self
        return completer
    }()
    
    func searchAddress(_ searchableText: String) {
        guard searchableText.isEmpty == false else { return }
        localSearchCompleter.queryFragment = searchableText
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            results = completer.results.map {
                AddressResult(title: $0.title, subtitle: $0.subtitle)
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
}

