//
//  Helpers.swift
//  WhileCompiler
//
//  Created by Hani Kazmi on 08/11/2014.
//  Copyright (c) 2014 Hani. All rights reserved.
//

import Foundation

// MARK: - Printable Protocol
extension Rexp: CustomStringConvertible {
    var description: String {
        switch self {
        case is Null:           return "Null"
        case is Empty:          return "Empty"
        case let r as Char:     return "Char(\"\(r.c)\")"
        case let r as Alt:      return "Alt(\(r.r1),\(r.r2))"
        case let r as Seq:      return "Seq(\(r.r1),\(r.r2))"
        case let r as Star:     return "Star(\(r.r))"
        case let r as Chars:    return "Chars(\"\(String(r.c))\")"
        case let r as Plus:     return "Plus(\(r.r))"
        case let r as Opt:      return "\(r.r)?"
        case let r as Ntimes:   return "Mult(\(r.r), \(r.n))"
        case let r as Mult:     return "Mult(\(r.r), \(r.n), \(r.m))"
        case let r as Not:      return "Not(\(r.r))"
        case let r as Rec:      return r.r.description
        default:                return "Error"
        }
    }
}

extension Val: CustomStringConvertible {
    var description: String {
        switch self {
        case is void:           return "Not matched"
        case let r as char:     return "\(r.c)"
        case let r as seq:      return "seq(\(r.v1), \(r.v2))"
        case let r as left:     return "left(\(r.v))"
        case let r as right:    return "right(\(r.v))"
        case let r as stars:    return "stars(\(r.vs))"
        case let r as rec:      return "\(r.x) : \(r.v)"
        default:                return "error"
        }
    }
}

extension Stmt: CustomStringConvertible {
    var description: String {
        switch self {
        case is Skip: return "Skip"
        case let t as If: return "If(\(t.a), \(t.bl1), \(t.bl2))"
        case let t as While: return "While(\(t.b), \(t.bl))"
        case let t as For: return "For(\(t.a), \(t.i), \(t.bl))"
        case let t as Assign: return "Assign(\(t.s), \(t.a))"
        case let t as Read: return "Read(\(t.s))"
        case let t as WriteS: return "Write(\(t.s))"
        case let t as Write: return "Write(\(t.s))"
        default: return ""
        }
    }
}

extension AExp: CustomStringConvertible {
    var description: String {
        switch self {
        case let t as Var: return "Var(\(t.s))"
        case let t as Num: return "Num(\(t.i))"
        case let t as Aop: return "Aop(\(t.o), \(t.a1), \(t.a2))"
        default: return ""
        }
    }
}

extension BExp: CustomStringConvertible {
    var description: String {
        switch self {
        case is True: return "True"
        case is False: return "False"
        case let t as Bop: return "Bop(\(t.o), \(t.a1), \(t.a2))"
        default: return ""
        }
    }
}

// MARK: - Extensions
extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    /// Returns the substring from the given range
    subscript(range: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[start..<end]
    }
    
    var count: Int { return self.utf16.count }
    /// Returns the first character
    var head: Character { return self[0] }
    /// Returns the original string minus the first character
    var tail: String { return self[1..<self.count] }
}

extension Array {
    /// Returns the original array minus the first element
    var tail: [Element] {
        return Array(self[1..<count])
    }
}

// MARK: - Helper functions
func count(_ r: Rexp) -> Int {
    switch r {
    case let r as BinaryRexp:   return 1 + count(r.r1) + count(r.r2)
    case let r as UnaryRexp:    return 1 + count(r.r)
    case let r as Ntimes:       return 1 + count(r.r)
    case let r as Mult:         return 1 + count(r.r)
    case let r as Not:          return count(r.r)
    case let r as Rec:          return count(r.r)
    default:                    return 1
    }
}

/// Returns a closure which is only evaluated when needed
func lazy<I, T>(_ p: @escaping () -> (I) -> T) -> (I) -> T {
    return  { p()($0) }
}

/// Reads a line from stdin
func readln() -> String {
    let standardInput = FileHandle.standardInput
    let data = NSString(data: standardInput.availableData, encoding:String.Encoding.utf8.rawValue)!
    return data.trimmingCharacters(in: .whitespacesAndNewlines)
}

// Opens a file and returns it as a String
func readfile(_ path: String) -> String {
    do {
        let str = try String(contentsOfFile: path)
        return str
    } catch let error {
        Swift.print("readFile: \(error)")
        return ""
    }
}

/// Write a string to a file
func writefile(_ file: String, path: String) {
    do {
        _ = try file.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
    } catch let error {
        Swift.print("readFile: \(error)")
    }
}

func execJasmin(_ path: String) {
    system("java -jar jasmin.jar \(path).j")
    system("java \(path)/\(path)")
}

func system(_ command: String) {
    var args = command.components(separatedBy: " ")
    let path = args.first
    args.remove(at: 0)
    
    let task = Process()
    task.launchPath = path
    task.arguments = args
    task.launch()
    task.waitUntilExit()
}

// Proposal: SE-0077

precedencegroup ComparisonPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
}
infix operator <> : ComparisonPrecedence

precedencegroup Additive {
    associativity: left
}
precedencegroup Multiplicative {
    associativity: left
    higherThan: Additive
}
precedencegroup BitwiseAnd {
    associativity: left
}
infix operator + : Additive
infix operator - : Additive
infix operator * : Multiplicative
infix operator & : BitwiseAnd

precedencegroup Exponentiative {
    associativity: left
    higherThan: Multiplicative
}
infix operator ** : Exponentiative


// MARK: - Custom Operators
infix operator ~ { associativity left precedence 150 }
infix operator ==> { precedence 140 }
prefix operator /
postfix operator *
postfix operator +
postfix operator %
