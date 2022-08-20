//
//  ContentView.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct ContentView: View {
    enum Sections: String, Identifiable, CaseIterable {
        case riskAttack = "Risk Attack Automation"
        #if !os(macOS)
        case riskCounter = "Risk Piece Counter"
        #endif
//        case riskAI = "Risk Artificial Intelligence"
        
        var id: Int { self.hashValue }
        var image: String {
            switch self {
            case .riskAttack:
                return "die.face.5.fill"
            #if !os(macOS)
            case .riskCounter:
                return "camera.viewfinder"
            #endif
//            case .riskAI:
//                return "globe.americas.fill"
            }
        }
    }
    
    @State private var selectedSection = Sections.riskAttack
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView(sidebar: {
            List(Sections.allCases, selection: $selectedSection) { section in
                HStack {
                    Image(systemName: section.image)
                    Text(section.rawValue)
                }
                .tag(section)
            }
        }, detail: {
            switch selectedSection {
            case .riskAttack:
                RiskAttackView()
            #if !os(macOS)
            case .riskCounter:
                RiskCounter()
            #endif
//            case .riskAI:
//                RiskAI()
            }
        })
        .frame(minWidth: 200, minHeight: 100)
        #else
        NavigationStack {
            List(Sections.allCases) { section in
                NavigationLink(value: section) {
                    HStack {
                        Image(systemName: section.image)
                        Text(section.rawValue)
                    }
                }
            }
            .navigationDestination(for: Sections.self, destination: {
                switch $0 {
                case .riskAttack:
                    RiskAttackView()
                case .riskCounter:
                    RiskCounter()
//                case .riskAI:
//                    RiskAI()
                }
            })
            .navigationTitle("Game Tools")
            .navigationBarTitleDisplayMode(.large)
        }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
