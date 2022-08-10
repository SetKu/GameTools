//
//  RiskCounter.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-09.
//

import SwiftUI

struct RiskCounter: View {
    @State private var image: UIImage? = nil
    @State private var color: CGColor = .init(
        red: 15, green: 85, blue: 247, alpha: 1
    )
    
    @State private var showingError = false
    @State private var error: String = ""
    
    @State private var picking = false
    @State private var useCamera = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Toggle("Use Camera", isOn: $useCamera)
                
                imageView
                
                ColorPicker("Armies Color", selection: $color)
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Risk Pieces Counter")
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK") { }
            })
            .sheet(isPresented: $picking, onDismiss: count, content: {
                ImagePicker(image: $image, useCamera: useCamera)
                    .ignoresSafeArea()
            })
        }
    }
    
    private var imageView: some View {
        Button(action: {
            picking = true
            
            #if os(iOS)
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.prepare()
            gen.impactOccurred()
            #endif
        }) {
            ZStack {
                Rectangle()
                    .foregroundColor(.primary.opacity(0.2))
                
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(10)
        }
    }
    
    private func count() {
        
    }
}

struct RiskCounter_Previews: PreviewProvider {
    static var previews: some View {
        RiskCounter()
    }
}
