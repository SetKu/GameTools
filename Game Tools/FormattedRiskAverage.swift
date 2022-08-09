//
//  FormattedRiskAverage.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-08.
//

import SwiftUI

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
        }
        .font(.system(size: 18))
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
            initialAttack: 37
        ))
    }
}
