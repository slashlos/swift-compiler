//
//  Compiler.swift
//  WhileCompiler
//
//  Created by Hani Kazmi on 08/12/2014.
//  Copyright (c) 2014 Hani. All rights reserved.
//
import Foundation

typealias Mem = [String:Int]
typealias Instrs = [String]

func compile_aexp(_ a: AExp, env: Mem) -> Instrs {
    switch a {
    case let a as Num: return ["ldc \(a.i)"]
    case let a as Var: return ["iload \(env[a.s]!)"]
    case let a as Aop where a.o == "+": return compile_aexp(a.a1, env: env) + compile_aexp(a.a2, env: env) + ["iadd"]
    case let a as Aop where a.o == "-": return compile_aexp(a.a1, env: env) + compile_aexp(a.a2, env: env) + ["isub"]
    case let a as Aop where a.o == "*": return compile_aexp(a.a1, env: env) + compile_aexp(a.a2, env: env) + ["imul"]
    case let a as Aop where a.o == "/": return compile_aexp(a.a1, env: env) + compile_aexp(a.a2, env: env) + ["idiv"]
    default: return []
    }
}

func compile_bexp(_ b: BExp, env: Mem, jmp: String) -> Instrs {
    switch b {
    case let b as Bop where b.o == "=": return compile_aexp(b.a1, env: env) + compile_aexp(b.a2, env: env) + ["if_icmpne \(jmp)"]
    case let b as Bop where b.o == "!=": return compile_aexp(b.a1, env: env) + compile_aexp(b.a2, env: env) + ["if_icmpeq \(jmp)"]
    case let b as Bop where b.o == ">": return compile_aexp(b.a1, env: env) + compile_aexp(b.a2, env: env) + ["if_icmple \(jmp)"]
    case let b as Bop where b.o == "<": return compile_aexp(b.a1, env: env) + compile_aexp(b.a2, env: env) + ["if_icmpge \(jmp)"]
    default: return []
    }
}

var var_count = 0
func calc_store( _ env: Mem, i: String) -> Mem {
    var _env = env
    if _env[i] == nil { _env[i] = var_count; var_count += 1 }
    return _env
}

var labl_count = 0
func calc_labl(_ x: String) -> String {
    labl_count += 1
    return "\(x)_\(labl_count)"
}

func compile_stmt(_ s: Stmt, env: Mem) -> (i: Instrs, e: Env) {
    switch s {
    case is Skip: return ([], env)
    case let s as Assign: let e = calc_store(env, i: s.s); return (compile_aexp(s.a, env: e) + ["istore \(e[s.s]!)"], e)
    case let s as If:
        let if_else = calc_labl("if_else")
        let if_end = calc_labl("if_end")
        let (i_bl, e) = compile_bl(s.bl1, env: env)
        let (e_bl, e2) = compile_bl(s.bl2, env: e)
        let If = compile_bexp(s.a, env: env, jmp: if_else)
        let Then = i_bl + ["goto \(if_end)"]
        let Else = ["\n\(if_else):\n"] + e_bl + ["\n\(if_end):\n"]
        return (If + Then + Else, e2)
    case let s as While:
        let w_begin = calc_labl("loop_begin")
        let w_end = calc_labl("loop_end")
        let (bl, e) = compile_bl(s.bl, env: env)
        let test = ["\n\(w_begin):\n"] + compile_bexp(s.b, env: env, jmp: w_end)
        let asm = bl + ["goto \(w_begin)"] + ["\n\(w_end):\n"]
        return (test + asm, e)
    case let s as For:
        let (s1, e) = compile_stmt(s.a, env: env)
        let f_begin = calc_labl("loop_begin")
        let f_end = calc_labl("loop_end")
        let (bl, e2) = compile_bl(s.bl, env: e)
        let bl2 = bl + ["iload \(e[s.a.s]!)", "ldc 1", "iadd", "istore \(e[s.a.s]!)"]
        let test = ["\n\(f_begin):\n"] + compile_bexp(Bop(o: "<", a1: Var(s.a.s), a2: s.i), env: e, jmp: f_end)
        let asm = bl2 + ["goto \(f_begin)"] + ["\n\(f_end):\n"]
        return (s1 + test + asm, e2)
    case let s as Read: let e = calc_store(env, i: s.s); return ([lRead] + ["istore \(e[s.s]!)"], e)
    case let s as WriteS: return (["ldc \(s.s)"] + [lWriteS], env)
    case let s as Write: return (compile_aexp(s.s, env: env) + [lWrite], env)
    default: return ([], env)
    }
}

func compile_bl(_ bl: Block, env: Mem) -> (i: Instrs, e: Env) {
    if bl.isEmpty { return ([], env) }
    let (i, e) = compile_stmt(bl.first!, env: env)
    let (i2, e2) = compile_bl(bl.tail, env: e)
    return  (i+i2, e2)
}

func compile(_ bl: Block) -> String {
    return Header + compile_bl(bl, env: Mem()).i.reduce("") { $0 + $1 + "\n" } + Footer
}

let Compile = { compile(satisfy(lstmts($0))) }

/// Compiles the path passed in as either the function parameter or program commandline argument
func compile_file(_ path: String = CommandLine.arguments[1]) {
    let content = readfile(path)
    let file_name = URL(fileURLWithPath:path).lastPathComponent
    let compiled = Compile(tokeniser(tok(content))).replacingOccurrences(of: "XXX", with: file_name)
    writefile(compiled, path: file_name + ".j")
    execJasmin(file_name)
}
