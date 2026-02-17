import Testing
import Foundation
@testable import personal_finance

struct NumberPadLogicTests {
    @Test func appendDigit() async throws {
        var text = ""
        NumberPadLogic.append("5", to: &text)
        #expect(text == "5")
        NumberPadLogic.append("3", to: &text)
        #expect(text == "53")
    }

    @Test func appendDecimalOnce() async throws {
        var text = "12"
        NumberPadLogic.append(".", to: &text)
        #expect(text == "12.")
        NumberPadLogic.append(".", to: &text)
        #expect(text == "12.")
    }

    @Test func maxTwoDecimalPlaces() async throws {
        var text = "12.34"
        NumberPadLogic.append("5", to: &text)
        #expect(text == "12.34")
    }

    @Test func maxAmount() async throws {
        var text = "9999999"
        NumberPadLogic.append("9", to: &text)
        #expect(text == "9999999")
    }

    @Test func deleteLast() async throws {
        var text = "123"
        NumberPadLogic.deleteLast(from: &text)
        #expect(text == "12")
    }

    @Test func deleteFromEmpty() async throws {
        var text = ""
        NumberPadLogic.deleteLast(from: &text)
        #expect(text == "")
    }

    @Test func leadingZeroPrevention() async throws {
        var text = "0"
        NumberPadLogic.append("0", to: &text)
        #expect(text == "0")
        NumberPadLogic.append("5", to: &text)
        #expect(text == "5")
    }

    @Test func formattedDisplay() async throws {
        #expect(NumberPadLogic.formatted("1250") == "1,250")
        #expect(NumberPadLogic.formatted("") == "0")
        #expect(NumberPadLogic.formatted("1234567") == "1,234,567")
        #expect(NumberPadLogic.formatted("12.5") == "12.5")
    }
}
