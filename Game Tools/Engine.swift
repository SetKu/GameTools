//
//  Engine.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-07.
//

import SwiftUI

protocol Engine {
    /// - Parameter number: The number of dice to roll.
    /// - Returns: An array of integers with the number specified between 0 and 7 (1, 2, 3, 4, 5, 6).
    static func rollDice(_ number: Int) -> [Int]
}

extension Engine {
    static func rollDice(_ number: Int) -> [Int] {
        var arr = [Int]()
        
        for _ in 0 ..< number {
            arr.append(Int.random(in: 1...6))
        }
        
        return arr
    }
}
