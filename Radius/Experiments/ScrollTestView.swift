//
//  ScrollTestView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 11/1/24.
//

import Foundation
import SwiftUI

//struct ScrollTestView: View {
//    var body: some View {
//        ScrollView {
//            VStack {
//                ForEach(0...15, id: \.self) { i in
//                    HStack {
//                        Spacer()
//                        Text("\(i)")
//                        Spacer()
//                    }
//                    .padding(20)
//                    .background(.blue)
//                    .cornerRadius(20)
//                }
//            }
//        }
//        .padding(.horizontal)
//        .bottomBlurScroll(10)
//    }
//}
//
///// We create a viewModifier that captures the generic content we want scrolling in the ScrollView
///// Then apply blur to a copy of that content and mask it to the bottom of the screen. Later a masked blur will
///// be implemented for the top of the scrollable content
/////
///// Source [https://medium.com/@brianmasse_94741/scroll-into-blur-creating-a-dissipating-effect-for-scrollviews-in-swiftui-c2f12d5c2744]
/////
///// While we can overlay and mask a simple content.blur() in ZStack, the actual blur will not stay fixed
/////
///// One way to accomplish is to read the scroll position of the ScrollView and apply the opposite offset to blur
///// to effectively pin it in place
/////
///// Detect scroll position [https://saeedrz.medium.com/detect-scroll-position-in-swiftui-3d6e0d81fc6b#:~:text=To%20detect%20the%20scroll%20position,to%20a%20given%20coordinate%20system.]
/////
///// Method relies on putting the content in its own coordinate space, attaching a geometryReader to read the frame data
///// from it, then sending it back up to the view with a preference key
///// The y componenet of this point will contain the ScrollView Offset
///// We use a preferenceKey, because a GeometryReader captures frame data during state update
///// So modifying a state var would cause 2 updates in the same frame, which is not allowed
//private struct ScrollOffsetPreferenceKey: PreferenceKey {
//
//    static var defaultValue: CGPoint = .zero
//
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
//}
//
//private struct BottomBlurScroll: ViewModifier {
//
//    // Coordinate space name
//    let coordinateSpaceName = "bottom_scroll"
//    let blur: CGFloat
//
//    @State private var scrollPosition: CGPoint = .zero
//
//    /// This is the gradient responsible for masking the blur effect.
//    /// The locations of the .clear and .white affect how large the effect is
//    let gradient = LinearGradient(
//        stops: [
//            .init(color: .white, location: 0.10),
//            .init(color: .clear, location: 0.25)
//        ],
//        startPoint: .bottom,
//        endPoint: .top
//    )
//
//    let invertedGradient = LinearGradient(
//        stops: [
//            .init(color: .clear, location: 0.10),
//            .init(color: .white, location: 0.25)
//        ],
//        startPoint: .bottom,
//        endPoint: .top
//    )
//
//    func body(content: Content) -> some View {
//        GeometryReader { topGeo in
//            // Geo outside the ScrollView. reads the frame of ony the visible portion of sv not the entire height of
//            // content (content can presumambly stretch far beyond the limited window of scroll view). trim content to
//            // that size and then align to top of Zdtack so it aligns
//            ScrollView(.vertical) {
//                ZStack(alignment: .top) {
//                    content
//
//                    // mask will fade out the bottom content to reveal the blur on top
//                        .mask(VStack {
//                            invertedGradient
//                                .frame(height: topGeo.size.height, alignment: .top)
//                                .offset(y: -scrollPosition.y)
//                            Spacer()
//                        })
//                    // Overlay the same content with a blur and a mask to trim it
//                    content
//                        .blur(radius: blur) // Simply applies the passed in blur radius value
//                        .frame(height: topGeo.size.height, alignment: .top) // Add a
//                        .mask(
//                            gradient // Linear gradient, same frame as height of top geo as content means the .bottom of
//                                // gradient rferes to bottom of the visible window fo scrollview and .top refers to top.
//                                // without this frame, .botom woudl refre to bottom of larger content
//                                .frame(height: topGeo.size.height)
//                                .offset(
//                                    y: -scrollPosition.y
//                                ) // offsetting the gradient by the negated scroll position effectively pins in place
//                            // insie scroll
//                        )
//                        .ignoresSafeArea() // blur to edge
//                }
//                .padding(.bottom, topGeo.size.height * 0.25)
//                // This reads the frame data in the defined coordinate space and
//                // writes to the preference key
//                .background(
//                    GeometryReader { geo in
//                        Color.clear.preference(
//                            key: ScrollOffsetPreferenceKey.self,
//                            value: geo.frame(in: .named(coordinateSpaceName)).origin
//                        )
//                    }
//                )
//                // this detects changes in the prefernceKey and sends them to thestate var in view
//                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
//                    scrollPosition = value
//                }
//            }
//            .coordinateSpace(name: coordinateSpaceName)
//        }
//    }
//}
//
/////**
//// .padding(.bottom, topGeo.size.height * 0.25)
////
//// The last thing to add is some bottom padding to the ZStack in the ScrollView so you can scroll just past the content to avoid covering up the bottom with the blur. I used the geometry reader so this buffer would always be 25% of the ScrollView window to match the size of the blur effect, however, any sufficiently big padding will do!
//// **/
//
//extension View {
//    func bottomBlurScroll(_ blur: CGFloat) -> some View {
//        modifier(BottomBlurScroll(blur: blur))
//    }
//}


extension View {
    func blurScroll(_ blur: CGFloat) -> some View {
        modifier(BlurScroll(blur: blur))
    }
}

private struct BlurScroll: ViewModifier {
    
    let blur: CGFloat
    let coordinateSpaceName = "scroll"
    
    @State private var scrollPosition: CGPoint = .zero
    
    func body(content: Content) -> some View {
        
        let gradient = LinearGradient(stops: [
            .init(color: .white, location: 0.10),
            .init(color: .clear, location: 0.25)],
                                      startPoint: .bottom,
                                      endPoint: .top)
        
        let invertedGradient = LinearGradient(stops: [
            .init(color: .clear, location: 0.10),
            .init(color: .white, location: 0.25)],
                                              startPoint: .bottom,
                                              endPoint: .top)
        
        GeometryReader { topGeo in
            ScrollView {
                ZStack(alignment: .top) {
                    content
                        .mask(
                            VStack {
                                invertedGradient
                                
                                    .frame(height: topGeo.size.height, alignment: .top)
                                    .offset(y:  -scrollPosition.y )
                                Spacer()
                            }
                        )
                    
                    content
                        .blur(radius: blur)
                        .frame(height: topGeo.size.height, alignment: .top)
                        .mask(gradient
                            .frame(height: topGeo.size.height)
                            .offset(y:  -scrollPosition.y )
                        )
                        .ignoresSafeArea()
                }
                .padding(.bottom, topGeo.size.height * 0.25)
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    self.scrollPosition = value
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
        .ignoresSafeArea()
    }
}

//MARK: PreferenceKey
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
