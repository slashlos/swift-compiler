//
//  Interpreter.swift
//  WhileCompiler
//
//  Created by Hani Kazmi on 03/12/2014.
//  Copyright (c) 2014 Hani. All rights reserved.
//

typealias Env = [String:Int]

func eval_aexp(a: AExp, env: Env) -> Int {
    switch a {
    case let a as Num: return a.i
    case let a as Var: return env[a.s]!
    case let a as Aop where a.o == "+": return eval_aexp(a.a1, env: env) + eval_aexp(a.a2, env: env)
    case let a as Aop where a.o == "-": return eval_aexp(a.a1, env: env) - eval_aexp(a.a2, env: env)
    case let a as Aop where a.o == "*": return eval_aexp(a.a1, env: env) * eval_aexp(a.a2, env: env)
    case let a as Aop where a.o == "/": return eval_aexp(a.a1, env: env) / eval_aexp(a.a2, env: env)
    default: return 0
    }
}

func eval_bexp(b: BExp, env: Env) -> Bool {
    switch b {
    case is True: return true
    case is False: return false
    case let b as Bop where b.o == "=": return eval_aexp(b.a1, env: env) == eval_aexp(b.a2, env: env)
    case let b as Bop where b.o == "!=": return eval_aexp(b.a1, env: env) != eval_aexp(b.a2, env: env)
    case let b as Bop where b.o == ">": return eval_aexp(b.a1, env: env) > eval_aexp(b.a2, env: env)
    case let b as Bop where b.o == "<": return eval_aexp(b.a1, env: env) < eval_aexp(b.a2, env: env)
    default: return false
    }
}

func eval_stmt(s: Stmt, env: Env) -> Env {
    var _env = env
    switch s {
    case is Skip: return env
    case let s as Assign: _env[s.s] = eval_aexp(s.a, env: env); return _env
    case let s as If where eval_bexp(s.a, env: env): return eval_bl(s.bl1, env: env)
    case let s as If: return eval_bl(s.bl2, env: env)
    case let s as While where eval_bexp(s.b, env: env): return eval_stmt(While(b: s.b, bl: s.bl), env: eval_bl(s.bl, env: env))
    case let s as Read: _env[s.s] = Int(readln()); return _env
    case let s as WriteS: print(s.s); return env
    case let s as Write: print(eval_aexp(s.s, env: env)); return env
    default: return env
    }
}

func eval_bl(bl: Block, env: Env) -> Env {
    return bl.isEmpty ? env : eval_bl(bl.tail, env: eval_stmt(bl.first!, env: env))
}

func eval(bl: Block) -> Env {
    return eval_bl(bl, env: Env())
}

/// Given a list of tokens, runs the resulting program and prints the variables
let Eval = { print(eval(satisfy(lstmts($0)))) }