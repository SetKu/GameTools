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
        
        var id: Int { self.hashValue }
    }
    
    @State private var selectedSection = Sections.riskAttack
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView(sidebar: {
            List(Sections.allCases, selection: $selectedSection) { section in
                Text(section.rawValue).tag(section)
            }
        }, detail: {
            switch selectedSection {
            case .riskAttack:
                RiskAttackView()
            }
        })
        .frame(minWidth: 200, minHeight: 100)
        #else
        NavigationStack {
            List(Sections.allCases) { section in
                NavigationLink(section.rawValue, value: section)
            }
            .navigationDestination(for: Sections.self, destination: {
                switch $0 {
                case .riskAttack:
                    RiskAttackView()
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
