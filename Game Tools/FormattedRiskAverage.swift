//
//  FormattedRiskAverage.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-08.
//

import SwiftUI
import Charts

struct FormattedRiskAverage: View {
    let average: RiskEngine.AttackAverage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Attacker's Average New Armies: \(average.attack)")
            Text("\(average.attackerLost ? "Lost: " : "Gained: +")\(Int(average.initialAttack) - average.attack)")
                .padding(.leading)
                .foregroundColor(.secondary)
            
            Text("Defender's Average New Armies: \(average.defence)")
            Text("\(average.defenderLost ? "Lost: " : "Gained: +")\(Int(average.initialDefence) - average.defence)")
                .padding(.leading)
                .foregroundColor(.secondary)
            
            chart
                .contextMenu(menuItems: {
                    ShareLink(
                        item: chartImage,
                        preview: SharePreview("Risk Simulation Chart", image: chartImage)
                    )
                })
                // As of Xcode 14 beta 5 this causes a crash on drop of the dragged item. Not sure why, I believe this is a bug with the new Transferable API within the system.
                .draggable(chartImage)
        }
        .font(.system(size: 18))
    }
    
    private let chartHeight: CGFloat = 250
    
    @MainActor
    private var chartImage: Image {
        let renderer = ImageRenderer(content: chart)
        renderer.proposedSize = ProposedViewSize(width: chartHeight * 1.5, height: chartHeight)
        renderer.scale = 3.0
        let cgImage = renderer.cgImage!
        
        #if os(macOS)
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        return Image(nsImage: image)
        #else
        let image = UIImage(cgImage: cgImage)
        return Image(uiImage: image)
        #endif
    }
    
    private var chart: some View {
        Chart {
            ForEach(average.attacksCondensed) { attack in
                let index = average.attacks.firstIndex(of: attack)!
                
                LineMark(
                    x: .value("Iteration", "\(index + 1)"),
                    y: .value("New Armies", attack.attack)
                )
                .foregroundStyle(by: .value("Side", "Attack"))
                .symbol(.pentagon)
                
                LineMark(
                    x: .value("Iteration", "\(index + 1)"),
                    y: .value("New Armies", attack.defence)
                )
                .foregroundStyle(by: .value("Side", "Defence"))
                .symbol(.circle)
            }
            
            RuleMark(y: .value("Average Attack", average.attack))
                .lineStyle(.init(lineWidth: 2, dash: [10]))
                .foregroundStyle(.primary.opacity(0.5))
            RuleMark(y: .value("Average Defence", average.defence))
                .lineStyle(.init(lineWidth: 2, dash: [10]))
                .foregroundStyle(.primary.opacity(0.8))
        }
        .chartXAxis(.hidden)
        .chartXAxisLabel("Iteration")
        .chartYAxisLabel(content: {
            Text("New Armies")
        })
        .frame(height: chartHeight)
        .padding(.top, 10)
    }
}

struct FormattedRiskAverage_Previews: PreviewProvider {
    static var previews: some View {
        FormattedRiskAverage(average: .init(
            defence: 25,
            attack: 32,
            attackerLost: true,
            defenderLost: true,
            initialDefence: 33,
            initialAttack: 37,
            attacks: []
        ))
    }
}
