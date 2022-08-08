//
//  RiskToolsView.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct RiskToolsView: View {
    @State private var response: GTRiskEngine.AttackResponse? = nil
    
    @State private var defence = 5.0
    @State private var attack = 8.0
    @State private var power = 3.0
    
    @State private var series = 5.0
    @State private var simulatingSeries = false
    @State private var minimumAttackReserve = 5.0
    
    @State private var showingError = false
    @State private var error: Error? = nil {
        didSet {
            showingError = true
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    adjustmentSliders
                    
                    if let response {
                        FormattedRiskResponse(response: response)
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(alignment: .trailing) {
                Spacer()
                runButton
            }
        }
        .alert(error?.localizedDescription ?? "", isPresented: $showingError, actions: {
            Button("OK") { }
        })
        .navigationTitle("Risk")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var adjustmentSliders: some View {
        VStack {
            Grid(alignment: .leading, horizontalSpacing: 10) {
                GridRow {
                    Image(systemName: "fork.knife")
                    Text("Attack:")
                    Text("\(Int(attack))")
                    Slider(value: $attack, in: 2...40, step: 1)
                }
                
                GridRow {
                    Image(systemName: "shield.fill")
                    Text("Defence:")
                    Text("\(Int(defence))")
                    Slider(value: $defence, in: 1...40, step: 1)
                }
                
                GridRow {
                    Image(systemName: "bolt.fill")
                    Text("Power:")
                    Text("\(Int(power))")
                    Slider(value: $power, in: 1...3, step: 1)
                }
            }
            
            Divider()
            
            Toggle("Simulating Series:", isOn: $simulatingSeries)
            
            if simulatingSeries {
                VStack(spacing: 5) {
                    HStack {
                        Image(systemName: "clock.arrow.2.circlepath")
                        Text("Maximum Iterations:")
                        Text("\(Int(series))")
                        Slider(value: $series, in: 1...20, step: 1)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Minimum Attack Reserve:")
                        Text("\(Int(minimumAttackReserve))")
                        Slider(value: $minimumAttackReserve, in: 1...20, step: 1)
                    }
                    
                    if attack < minimumAttackReserve + power {
                        Text("Warning: No attacks will occur. Attacking armies plus power are equal to the minimum attack reserve.")
                    }
                }
                .padding(.leading)
                .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 20))
    }
    
    private var runButton: some View {
        Button(action: {
            do {
                let config = GTRiskEngine.AttackConfiguration(
                    defence: Int(defence),
                    attack: Int(attack),
                    power: Int(power)
                )
                
                if simulatingSeries {
                    response = try GTRiskEngine.simulateAttackSeries(
                        Int(series),
                        withConfig: config,
                        minimumAttackReserve: Int(minimumAttackReserve)
                    )
                    
                    return
                }
                
                response = try GTRiskEngine.simulateAttack(config: config)
            }
            catch {
                self.error = error as? GTRiskEngine.AttackErrors
            }
        }) {
            Label("Simulate", systemImage: "play.fill")
                .foregroundColor(.white)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.blue.cornerRadius(12).shadow(radius: 5))
        }
        .frame(width: 150)
    }
}

struct RiskTools_Previews: PreviewProvider {
    static var previews: some View {
        RiskToolsView()
    }
}
