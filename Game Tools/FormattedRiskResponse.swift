//
//  FormattedRiskResponse.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct FormattedRiskResponse: View {
    let response: RiskEngine.AttackResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Attacker's New Armies: \(response.attack)")
            Text("\(response.attackerLost ? "Lost: " : "Gained: +")\(Int(response.initialAttack) - response.attack)")
                .padding(.leading)
                .foregroundColor(.secondary)
            
            Text("Defender's New Armies: \(response.defence)")
            Text("\(response.defenderLost ? "Lost: " : "Gained: +")\(Int(response.initialDefence) - response.defence)")
                .padding(.leading)
                .foregroundColor(.secondary)
        }
        .font(.system(size: 18))
        
        VStack(alignment: .center, spacing: 12) {
            ForEach(response.rolls) { roll in
                let label = response.rolls.firstIndex(of: roll)! + 1
                
                ZStack(alignment: .topLeading) {
                    RiskRollsView(roll: roll)
                    
                    if response.rolls.count > 1 {
                        Text("\(label)")
                            .font(.system(size: 30, design: .rounded))
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                            .frame(width: 70)
                            .offset(x: -70)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FormattedRiskResponse_Previews: PreviewProvider {
    static var previews: some View {
        FormattedRiskResponse(response: .init(
            rolls: [.init(attack: [2, 1, 1], defence: [5, 4])],
            defence: 5,
            attack: 5,
            attackerLost: true,
            defenderLost: false,
            initialDefence: 5,
            initialAttack: 7)
        )
    }
}
