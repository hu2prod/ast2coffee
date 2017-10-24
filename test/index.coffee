assert = require 'assert'

mod = require '../src/index.coffee'
gen = mod.gen
Type = require 'type'
type = (t)->new Type t
ast = require 'ast4gen'

var_d = (name, scope, _type='int')->
  scope.list.push t = new ast.Var_decl
  t.name = name
  t.type = type _type
  
  t = new ast.Var
  t.name = name
  t.type = type _type
  t

ci = (val)->
  t = new ast.Const
  t.val = val
  t.type = type 'int'
  t

cs = (val)->
  t = new ast.Const
  t.val = val
  t.type = type 'string'
  t

un = (a, op)->
  t = new ast.Un_op
  t.a = a
  t.op= op
  t

bin = (a, op, b)->
  t = new ast.Bin_op
  t.a = a
  t.b = b
  t.op= op
  t

fnd = (name, _type, arg_name_list, scope_list)->
  t = new ast.Fn_decl
  t.name = name
  t.arg_name_list = arg_name_list
  t.type = type _type
  t.scope.list = scope_list
  t

describe 'index section', ()->
  it '@', ()->
    assert.equal gen(new ast.This), "@"
    return
  
  it '1', ()->
    scope = new ast.Scope
    scope.list.push ci('1')
    assert.equal gen(scope), "1"
    return
  
  it '"1"', ()->
    scope = new ast.Scope
    scope.list.push cs('1')
    assert.equal gen(scope), '"1"'
    return
  
  it 'a', ()->
    scope = new ast.Scope
    scope.list.push var_d('a', scope)
    assert.equal gen(scope), "a"
    return
  
  it '+a', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push un(a,"PLUS")
    assert.equal gen(scope), "+(a)"
    return
  
  it 'a+b', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push bin(a,"ADD",b)
    assert.equal gen(scope), "(a + b)"
    return
  
  it 'a^b bool', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push bin(a,"BOOL_XOR",b)
    assert.equal gen(scope), "!!(a ^ b)"
    return
  
  it '[]', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Array_init
    assert.equal gen(scope), "[]"
    return
  
  it '[a]', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Array_init
    t.list.push a
    assert.equal gen(scope), "[a]"
    return
  
  it '{}', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Hash_init
    assert.equal gen(scope), "{}"
    return
  
  it '[a]', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Hash_init
    t.hash.k = a
    assert.equal gen(scope), '{"k": a}'
    return
  
  it 'a()', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Fn_call
    t.fn = a
    assert.equal gen(scope), '(a)()'
    return
  
  it 'a(b)', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push t = new ast.Fn_call
    t.fn = a
    t.arg_list.push b
    assert.equal gen(scope), '(a)(b)'
    return
  # ###################################################################################################
  #    stmt
  # ###################################################################################################
  it 'if a {b}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push t = new ast.If
    t.cond = a
    t.t.list.push b
    assert.equal gen(scope), '''
      if a
        b
    '''
    return
  
  it 'if a {b} {c}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    c = var_d('c', scope)
    scope.list.push t = new ast.If
    t.cond = a
    t.t.list.push b
    t.f.list.push c
    assert.equal gen(scope), '''
      if a
        b
      else
        c
    '''
    return
  
  it 'if a {} {c}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    c = var_d('c', scope)
    scope.list.push t = new ast.If
    t.cond = a
    t.f.list.push c
    assert.equal gen(scope), '''
      unless a
        c
    '''
    return
  # ###################################################################################################
  it 'switch a {k:b}', ()->
    scope = new ast.Scope
    a = var_d('a', scope, 'string')
    b = var_d('b', scope)
    scope.list.push t = new ast.Switch
    t.cond = a
    t.hash["k"] = b
    assert.equal gen(scope), '''
      switch a
        when "k"
          b
    '''
    return
  it 'switch a {k:b}{k2:0}', ()->
    scope = new ast.Scope
    a = var_d('a', scope, 'string')
    b = var_d('b', scope)
    scope.list.push t = new ast.Switch
    t.cond = a
    t.hash["k"] = b
    t.hash["k2"] = new ast.Scope
    assert.equal gen(scope), '''
      switch a
        when "k"
          b
        when "k2"
          0
    '''
    return
  
  it 'switch a {1:b}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push t = new ast.Switch
    t.cond = a
    t.hash["1"] = b
    assert.equal gen(scope), '''
      switch a
        when 1
          b
    '''
    return
  
  it 'switch a {1:b} default{c}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    c = var_d('c', scope)
    scope.list.push t = new ast.Switch
    t.cond = a
    t.hash["1"] = b
    t.f.list.push c
    assert.equal gen(scope), '''
      switch a
        when 1
          b
        else
          c
    '''
    return
  # ###################################################################################################
  it 'loop a', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Loop
    t.scope.list.push a
    assert.equal gen(scope), '''
      loop
        a
    '''
    return
  # ###################################################################################################
  it 'while a {b}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push t = new ast.While
    t.cond = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      while a
        b
    '''
    return
  
  it 'continue', ()->
    assert.equal gen(new ast.Continue), 'continue'
    return
  
  it 'break', ()->
    assert.equal gen(new ast.Break), 'break'
    return
  # ###################################################################################################
  it 'for i in [1 ... 10] a', ()->
    scope = new ast.Scope
    i = var_d('i', scope)
    a = var_d('a', scope)
    
    scope.list.push t = new ast.For_range
    t.i = i
    t.a = ci '1'
    t.b = ci '10'
    t.scope.list.push a
    assert.equal gen(scope), '''
      for i in [1 ... 10]
        a
    '''
    return
  
  it 'for i in [1 .. 10] a', ()->
    scope = new ast.Scope
    i = var_d('i', scope)
    a = var_d('a', scope)
    
    scope.list.push t = new ast.For_range
    t.i = i
    t.exclusive = false
    t.a = ci '1'
    t.b = ci '10'
    t.scope.list.push a
    assert.equal gen(scope), '''
      for i in [1 .. 10]
        a
    '''
    return
  
  it 'for i in [1 .. 10] by 2 a', ()->
    scope = new ast.Scope
    i = var_d('i', scope)
    a = var_d('a', scope)
    
    scope.list.push t = new ast.For_range
    t.i = i
    t.exclusive = false
    t.a = ci '1'
    t.b = ci '10'
    t.step = ci '2'
    t.scope.list.push a
    assert.equal gen(scope), '''
      for i in [1 .. 10] by 2
        a
    '''
    return
  # ###################################################################################################
  it 'for v in a b', ()->
    scope = new ast.Scope
    v = var_d('v', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_array
    t.v = v
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for v in a
        b
    '''
    return
  
  it 'for v,k in a b', ()->
    scope = new ast.Scope
    v = var_d('v', scope)
    k = var_d('k', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_array
    t.k = k
    t.v = v
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for v,k in a
        b
    '''
    return
  
  it 'for _skip,k in a b', ()->
    scope = new ast.Scope
    k = var_d('k', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_array
    t.k = k
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for _skip,k in a
        b
    '''
    return
  # ###################################################################################################
  it 'for v of a b', ()->
    scope = new ast.Scope
    v = var_d('v', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_hash
    t.v = v
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for _skip,v of a
        b
    '''
    return
  
  it 'for v,k of a b', ()->
    scope = new ast.Scope
    v = var_d('v', scope)
    k = var_d('k', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_hash
    t.k = k
    t.v = v
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for k,v of a
        b
    '''
    return
  
  it 'for _skip,k of a b', ()->
    scope = new ast.Scope
    k = var_d('k', scope)
    a = var_d('a', scope)
    b = var_d('b', scope)
    
    scope.list.push t = new ast.For_hash
    t.k = k
    t.t = a
    t.scope.list.push b
    assert.equal gen(scope), '''
      for k of a
        b
    '''
    return
  # ###################################################################################################
  it 'return', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Ret
    assert.equal gen(scope), 'return'
    return
  
  it 'return 1', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Ret
    t.t = ci '1'
    assert.equal gen(scope), 'return (1)'
    return
  # ###################################################################################################
  it 'try', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    b = var_d('b', scope)
    scope.list.push t = new ast.Try
    t.t.list.push a
    t.c.list.push b
    t.exception_var_name = 'e'
    assert.equal gen(scope), '''
      try
        a
      catch e
        b
    '''
    return
  # ###################################################################################################
  it 'throw "err"', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Throw
    t.t = cs 'err'
    assert.equal gen(scope), 'throw new Error("err")'
    return
  
  it 'Fn_decl', ()->
    scope = new ast.Scope
    scope.list.push fnd('fn', type('function<void>'), [], [])
    assert.equal gen(scope), 'fn = ()->\n  '
    
  describe 'Class_decl', ()->
    it 'Empty', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      assert.equal gen(scope), 'class A\n  '
    
    it 'Method', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      t.scope.list.push fnd('fn', type('function<void>'), [], [])
      assert.equal gen(scope), '''
        class A
          fn : ()->
            
        '''