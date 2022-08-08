//
//  GTRiskEngine.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import Foundation

struct GTRiskEngine: GTEngine {
    private init() { }
    
    struct Roll: Identifiable, Equatable {
        let attack: [Int]
        let defence: [Int]
        let id = UUID()
    }
    
    struct AttackResponse {
        let rolls: [Roll]
        let defence: Int
        let attack: Int
        let attackerLost: Bool
        let defenderLost: Bool
        let initialDefence: Int
        let initialAttack: Int
    }
    
    enum AttackErrors: String, Error {
        case unableToAttack = "Unable to attack."
        case unableToDefend = "Unable to defend."
        case invalidPower = "Invalid power value."
        case invalidSmartThreshold = "Invalid smart threshold."
    }
    
    struct AttackConfiguration {
        let defence: Int
        let attack: Int
        let power: Int
        let smartThreshold: Int?
        
        /// - Parameters:
        ///   - defence: The number of armies the defending territory holds.
        ///   - attack: The number of armies the attacking territory holds.
        ///   - power: The number of dice the attacker is rolling.
        ///   - smartThreshold: If not nil, the average dice roll from the attacker which the defender will roll the minimum number of dice (1) against.
        init(defence: Int, attack: Int, power: Int, smartThreshold: Int? = 4) {
            self.defence = defence
            self.attack = attack
            self.power = power
            self.smartThreshold = smartThreshold
        }
    }
    
    /// Calculates the result of an attack in the game Risk.
    /// - Returns: A response indicating the new defence and attack values for the corresponding territories, along with the simulated rolls made by the attacker and defender.
    ///
    /// For more info, feel free to check out the official rules of the game at https://www.ultraboardgames.com/risk/game-rules.php.
    static func simulateAttack(config: AttackConfiguration) throws -> AttackResponse {
        guard config.defence > 0 else { throw AttackErrors.unableToDefend }
        guard config.attack  > 1 else { throw AttackErrors.unableToAttack }
        guard config.power   > 0 else { throw AttackErrors.invalidPower   }
        
        if let smartThreshold = config.smartThreshold {
            guard 1...6 ~= smartThreshold else {
                throw AttackErrors.invalidSmartThreshold
            }
        }
        
        var attRolls = Self.rollDice(config.power)
        let attAvg = attRolls.reduce(into: 0, { $0 += $1 }) / config.power
        
        var defRolls: [Int]
        
        if let smartThreshold = config.smartThreshold {
            let attGood = attAvg >= smartThreshold
            defRolls = attGood ? Self.rollDice(1) : Self.rollDice(2)
        } else {
            defRolls = Self.rollDice(1)
        }
        
        attRolls.sort(by: { $0 > $1 })
        defRolls.sort(by: { $0 > $1 })
        
        var newValues: (Int, Int) = (config.defence, config.attack)
        
        for (index, defRoll) in defRolls.enumerated() {
            if index > attRolls.count - 1 { break }
            
            let attRoll = attRolls[index]
            
            if attRoll > defRoll {
                newValues.0 -= 1
            } else {
                newValues.1 -= 1
            }
        }
        
        newValues.0 = max(newValues.0, 0)
        newValues.1 = max(newValues.1, 0)
        
        let response = AttackResponse(
            rolls: [Roll(attack: attRolls, defence: defRolls)],
            defence: newValues.0,
            attack: newValues.1,
            attackerLost: newValues.1 < config.attack,
            defenderLost: newValues.0 < config.defence,
            initialDefence: config.defence,
            initialAttack: config.attack
        )
        
        return response
    }
    
    static func simulateAttackSeries(
        _ maximumIterations: Int,
        withConfig config: AttackConfiguration,
        minimumAttackReserve: Int? = nil
    ) throws -> AttackResponse {
        var defence = config.defence
        var attack = config.attack
        var rolls = [Roll]()
        
        for _ in 0 ..< maximumIterations {
            if attack - config.power < minimumAttackReserve ?? 1 { break }
            if defence < 1 || attack < 2 { break }
            
            let config = AttackConfiguration(defence: defence, attack: attack, power: config.power)
            let results = try simulateAttack(config: config)
            
            defence = results.defence
            attack = results.attack
            rolls.append(results.rolls.first!)
        }
        
        let response = AttackResponse(
            rolls: rolls,
            defence: defence,
            attack: attack,
            attackerLost: attack < config.attack,
            defenderLost: defence < config.defence,
            initialDefence: config.defence,
            initialAttack: config.attack
        )
        
        return response
    }
    
//    static func averageAttacks(responses: [AttackResponse]) -> AttackResponse {
//
//    }
//
//    static func findBestAttack() -> SomeValue {
//
//    }
}