//
//  RollsView.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

struct RiskRollsView: View {
    let roll: RiskEngine.Roll
    private static let diceSize: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ForEach(roll.attack, id: \.self) { roll in
                    Image(systemName: "die.face.\(roll)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Self.diceSize, height: Self.diceSize)
                }
            }
            .frame(height: Self.diceSize)
            
            HStack {
                ForEach(roll.defence, id: \.self) { roll in
                    Image(systemName: "die.face.\(roll).fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Self.diceSize, height: Self.diceSize)
                }
            }
            .frame(height: Self.diceSize)
        }
    }
}

struct RiskRollsView_Previews: PreviewProvider {
    static var previews: some View {
        RiskRollsView(roll: .init(attack: [5, 3, 2], defence: [6, 2]))
    }
}
