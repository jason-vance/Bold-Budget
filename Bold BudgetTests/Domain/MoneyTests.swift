//
//  MoneyTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 9/28/24.
//

import Testing
import Foundation

struct MoneyTests {

    @Test func formatsValueToCurrencyString() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let money = Money(100)!
        
        #expect(money.formatted() == "$100.00")
        
        let china = Locale.init(identifier: "zh_CN")
        #expect(money.formatted(locale: china) == "CN¥100.00")
        
        let japan = Locale.init(identifier: "ja_JP")
        #expect(money.formatted(locale: japan) == "¥100")
    }
    
    @Test func addition() {
        let one = Money(1)!
        let two = Money(2)!
        let added = one + two
        #expect(added.formatted() == "$3.00")
    }
    
    @Test func equality() {
        let a = Money(2)!
        let b = Money(2)!
        #expect(a == b)
    }
}
