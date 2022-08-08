//
//  ContentView.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct ContentView: View {
    enum Sections: String, Identifiable, CaseIterable {
        case risk = "Risk Tools"
        
        var id: Int { self.hashValue }
    }
    
    @State private var selectedSection = Sections.risk
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView(sidebar: {
            List(Sections.allCases, selection: $selectedSection) { section in
                Text(section.rawValue).tag(section)
            }
        }, detail: {
            switch selectedSection {
            case .risk:
                RiskTools()
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
                case .risk:
                    RiskToolsView()
                }
            })
            .navigationTitle("Game Tools")
        }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
