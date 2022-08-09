//
//  RiskAttackView.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct RiskAttackView: View {
    @State private var response: RiskEngine.AttackResponse? = nil
    @State private var average: RiskEngine.AttackAverage? = nil
    
    @State private var defence = 15.0
    @State private var attack = 25.0
    @State private var power = 3.0
    
    @State private var series = 40.0
    @State private var simulatingSeries = false
    @State private var minimumAttackReserve = 10.0
    @State private var sampleSize = 25.0
    
    @State private var showingError = false
    @State private var error: Error? = nil {
        didSet {
            showingError = true
        }
    }
    
    @State private var runningTask: Task<(), Never>? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    adjustmentSliders
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Outcome")
                            .font(.system(size: 25, weight: .bold))
                            .bold()
                        
                        if let response {
                            FormattedRiskResponse(response: response)
                                .transition(.opacity)
                        } else if let average {
                            FormattedRiskAverage(average: average)
                                .transition(.opacity)
                        }
                    }
                    .animation(.linear(duration: 0.4), value: response)
                    .animation(.linear(duration: 0.4), value: average)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    runButton
                    simulateButton
                }
            }
        }
        .alert(error?.localizedDescription ?? "", isPresented: $showingError, actions: {
            Button("OK") { }
        })
        .navigationTitle("Risk™")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var adjustmentSliders: some View {
        VStack {
            let valueWidth: CGFloat = 50
            
            Grid(alignment: .leading, horizontalSpacing: 10) {
                GridRow {
                    Image(systemName: "fork.knife")
                    Text("Attack:")
                    Text("\(Int(attack))")
                        .frame(width: valueWidth)
                    Slider(value: $attack, in: 2...90, step: 1)
                }
                
                GridRow {
                    Image(systemName: "shield.fill")
                    Text("Defence:")
                    Text("\(Int(defence))")
                        .frame(width: valueWidth)
                    Slider(value: $defence, in: 1...90, step: 1)
                }
                
                GridRow {
                    Image(systemName: "bolt.fill")
                    Text("Power:")
                    Text("\(Int(power))")
                        .frame(width: valueWidth)
                    Slider(value: $power, in: 1...3, step: 1)
                }
                
                GridRow {
                    Image(systemName: "rectangle.3.group.fill")
                    Text("Simulation Sample Size:")
                    Text("\(Int(sampleSize))")
                        .frame(width: valueWidth)
                    Slider(value: $sampleSize, in: 1...1000, step: 1)
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
                            .frame(width: valueWidth)
                        Slider(value: $series, in: 1...100, step: 1)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Minimum Attack Reserve:")
                        Text("\(Int(minimumAttackReserve))")
                            .frame(width: valueWidth)
                        Slider(value: $minimumAttackReserve, in: 1...90, step: 1)
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
    
    private struct BottomStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(.white)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.blue.cornerRadius(12).shadow(radius: 5))
                .frame(width: 150)
                .shadow(radius: 5)
                .opacity(configuration.isPressed ? 0.5 : 1)
        }
    }
    
    private var runButton: some View {
        Button(action: {
            if runningTask != nil {
                runningTask!.cancel()
                runningTask = nil
                return
            }
            
            runOnce()
        }) {
            Group {
                if runningTask != nil {
                    ProgressView()
                } else {
                    Label("Run Once", systemImage: "play.fill")
                }
            }
        }
        .buttonStyle(BottomStyle())
    }
    
    private var simulateButton: some View {
        Button(action: {
            if runningTask != nil {
                runningTask!.cancel()
                runningTask = nil
                return
            }
            
            simulate()
        }) {
            Group {
                if runningTask != nil {
                    ProgressView()
                } else {
                    Label("Find Average", systemImage: "repeat")
                }
            }
        }
        .buttonStyle(BottomStyle())
    }
    
    private func runOnce() {
        runningTask = Task {
            defer {
                DispatchQueue.main.async {
                    self.runningTask = nil
                }
            }
            
            do {
                let config = RiskEngine.AttackConfiguration(
                    defence: Int(defence),
                    attack: Int(attack),
                    power: Int(power)
                )
                
                let response: RiskEngine.AttackResponse
                
                if simulatingSeries {
                    response = try RiskEngine.simulateAttackSeries(
                        Int(series),
                        withConfig: config,
                        minimumAttackReserve: Int(minimumAttackReserve)
                    )
                    
                } else {
                    response = try RiskEngine.simulateAttack(config: config)
                }
                
                DispatchQueue.main.async {
                    self.average = nil
                    self.response = response
                }
            }
            catch {
                self.error = error
            }
        }
    }
    
    private func simulate() {
        runningTask = Task {
            defer {
                DispatchQueue.main.async {
                    self.runningTask = nil
                }
            }
            
            do {
                let config = RiskEngine.AttackConfiguration(
                    defence: Int(defence),
                    attack: Int(attack),
                    power: Int(power)
                )
                
                let seriesConfig = RiskEngine.AttackSeriesConfiguration(
                    maximumIterations: Int(series),
                    simConfig: config
                )
                
                let average: RiskEngine.AttackAverage
                
                if simulatingSeries {
                    average = try RiskEngine.averageAttackSeries(
                        sampleSize: Int(sampleSize),
                        simSeriesConfig: seriesConfig
                    )
                } else {
                    average = try RiskEngine.averageAttack(
                        sampleSize: Int(sampleSize),
                        simConfig: config
                    )
                }
                
                DispatchQueue.main.async {
                    self.response = nil
                    self.average = average
                }
            }
            catch {
                self.error = error
            }
        }
    }
}

struct RiskTools_Previews: PreviewProvider {
    static var previews: some View {
        RiskAttackView()
    }
}
