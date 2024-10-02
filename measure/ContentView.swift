//
//  ContentView.swift
//  measure
//
//  Created by Dason Tiovino on 02/10/24.
//

import SwiftUI
import RealityKit
import NotificationCenter

struct ContentView : View {

    var body: some View {
        
            ZStack {
                ARViewContainer().edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Button(action: {
                        NotificationCenter.default.post(name: .placeModel, object: nil)
                    }){
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                            .padding()
                    }
                }
            }
        
    }

}

#Preview {
    ContentView()
}
