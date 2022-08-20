//
//  GTRiskEngine.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import Foundation
import CoreGraphics
import Vision

#if !os(macOS)
import UIKit
#endif

struct RiskEngine: Engine {
    private init() { }
    
    // MARK: - Object Counter
    
    final class Counter: ObservableObject {
        enum Model: String, CaseIterable {
            case v1 = "V1"
            case v2 = "V2"
            case v3 = "V3"
            
            var mlModel: MLModel {
                switch self {
                case .v1:
                    return (try! RiskPieceDetectorV1(configuration: .init())).model
                case .v2:
                    return (try! RiskPieceDetectorV2(configuration: .init())).model
                case .v3:
                    return (try! RiskPieceDetectorV3(configuration: .init())).model
                }
            }
        }
        
        @Published var currentModel: Model
        private var visionModel: VNCoreMLModel { try! VNCoreMLModel(for: currentModel.mlModel) }
        
        init() { self.currentModel = .v1 }
        
        func detectObjects(image: CGImage) async throws -> [VNRecognizedObjectObservation] {
            var returnVal = [VNRecognizedObjectObservation]()
            
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    returnVal = results
                }
            }
            
            #if targetEnvironment(simulator)
            request.usesCPUOnly
            #endif
            
            #if os(macOS)
            let handler = VNImageRequestHandler(cgImage: image)
            #else
            let orientation: CGImagePropertyOrientation
            
            switch await UIDevice.current.orientation {
            case .portraitUpsideDown:
                orientation = .down
                break
            case .landscapeLeft:
                orientation = .left
                break
            case .landscapeRight:
                orientation = .right
                break
            default:
                orientation = .up
            }
            
            let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
            #endif
            
            try handler.perform([request])
            
            return returnVal
        }
        
        // MARK: Old Rectangle Detection
        
//        static func detectObjects(image: CGImage) throws -> [VNRectangleObservation] {
//            let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
//
//            var results = [VNRectangleObservation]()
//            let request = VNDetectRectanglesRequest { request, error in
//                if request.results != nil {
//                    results.append(contentsOf: request.results! as! [VNRectangleObservation])
//                }
//            }
//
//            // Customize & configure the request to detect only certain rectangles.
//            request.maximumObservations = 0
//            request.minimumConfidence = 0.8 // Be confident.
//            request.minimumAspectRatio = 0.2 // height / width
//            request.minimumSize = 0.05
//
//            #if targetEnvironment(simulator)
//            request.usesCPUOnly = true
//            #endif
//
//            try handler.perform([request])
//            return results
//        }
    }
    
    // MARK: - Attack Simulators
    
    struct Roll: Identifiable, Equatable {
        let attack: [Int]
        let defence: [Int]
        let id = UUID()
    }
    
    struct AttackResponse: Equatable, Identifiable {
        let rolls: [Roll]
        let defence: Int
        let attack: Int
        let attackerLost: Bool
        let defenderLost: Bool
        let initialDefence: Int
        let initialAttack: Int
        let id = UUID()
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
    
    static func averageAttack(sampleSize: Int, simConfig: AttackConfiguration) throws -> AttackAverage {
        var responses = [AttackResponse]()
        
        for _ in 0 ..< sampleSize {
            responses.append(try simulateAttack(config: simConfig))
        }
        
        let average = averageOutcome(fromAttacks: responses)
        return average
    }
    
    /// Simulates a series of attacks and returns a response with the outcome of making all those attacks.
    static func simulateAttackSeries(
        _ maximumIterations: Int,
        withConfig config: AttackConfiguration,
        minimumAttackReserve: Int?
    ) throws -> AttackResponse {
        var defence = config.defence
        var attack = config.attack
        var rolls = [Roll]()
        
        for _ in 0 ..< maximumIterations {
            if attack - config.power <= minimumAttackReserve ?? 1 { break }
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
    
    struct AttackSeriesConfiguration {
        let maximumIterations: Int
        let simConfig: AttackConfiguration
        let minimumAttackReserve: Int?
        
        init(maximumIterations: Int, simConfig: AttackConfiguration, minimumAttackReserve: Int? = nil) {
            self.maximumIterations = maximumIterations
            self.simConfig = simConfig
            self.minimumAttackReserve = minimumAttackReserve
        }
    }
    
    static func averageAttackSeries(sampleSize: Int, simSeriesConfig: AttackSeriesConfiguration) throws -> AttackAverage {
        var responses = [AttackResponse]()
        
        for _ in 0 ..< sampleSize {
            responses.append(
                try simulateAttackSeries(
                    simSeriesConfig.maximumIterations,
                    withConfig: simSeriesConfig.simConfig,
                    minimumAttackReserve: simSeriesConfig.minimumAttackReserve
                )
            )
        }
        
        let average = averageOutcome(fromAttacks: responses)
        return average
    }
    
    struct AttackAverage: Equatable {
        let defence: Int
        let attack: Int
        let attackerLost: Bool
        let defenderLost: Bool
        let initialDefence: Int
        let initialAttack: Int
        let attacks: [AttackResponse]
        
        init(defence: Int, attack: Int, attackerLost: Bool, defenderLost: Bool, initialDefence: Int, initialAttack: Int, attacks: [AttackResponse]) {
            self.defence = defence
            self.attack = attack
            self.attackerLost = attackerLost
            self.defenderLost = defenderLost
            self.initialDefence = initialDefence
            self.initialAttack = initialAttack
            self.attacks = attacks
            
            if attacks.count > 50 {
                var attacks = attacks
                
                while attacks.count > 50 {
                    attacks = attacks.filter { _ in
                        Bool.random()
                    }
                }
                
                self.attacksCondensed = attacks
                
                return
            }
            
            self.attacksCondensed = attacks
        }
        
        let attacksCondensed: [AttackResponse]
    }

    static func averageOutcome(fromAttacks attacks: [AttackResponse]) -> AttackAverage {
        let defenceAverage = attacks.map(\.defence).reduce(into: 0, { $0 += $1 }) / attacks.map(\.defence).count
        let attackAverage = attacks.map(\.attack).reduce(into: 0, { $0 += $1 }) / attacks.map(\.attack).count
        
        let initialAttack = attacks.first?.initialAttack ?? 2
        let initialDefence = attacks.first?.initialDefence ?? 1
        
        let response = AttackAverage(
            defence: defenceAverage,
            attack: attackAverage,
            attackerLost: attackAverage < initialAttack,
            defenderLost: defenceAverage < initialDefence,
            initialDefence: initialAttack,
            initialAttack: initialDefence,
            attacks: attacks
        )
        
        return response
    }
}
