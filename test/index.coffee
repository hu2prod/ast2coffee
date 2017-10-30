assert = require 'assert'

mod = require '../src/index.coffee'
gen = mod.gen
Type = require 'type'
ast = require 'ast4gen'

_var = (name, _type='int')->
  t = new ast.Var
  t.name = name
  t.type = new Type _type
  t

var_d = (name, scope, _type='int')->
  scope.list.push t = new ast.Var_decl
  t.name = name
  t.type = new Type _type
  
  t = new ast.Var
  t.name = name
  t.type = new Type _type
  t

ci = (val)->
  t = new ast.Const
  t.val = val
  t.type = new Type 'int'
  t

cs = (val)->
  t = new ast.Const
  t.val = val
  t.type = new Type 'string'
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
  t.type = new Type _type
  t.scope.list = scope_list
  t

fa = (target, name, _type)->
  t = new ast.Field_access
  t.t = target
  t.name = name
  t.type = new Type _type
  t

describe 'index section', ()->
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
  
  hash =
    PLUS    : "+(a)"
    INC_RET : "++(a)"
    RET_INC : "(a)++"
    DEC_RET : "--(a)"
    RET_DEC : "(a)--"
    BOOL_NOT: "!(a)"
    BIT_NOT : "~(a)"
    MINUS   : "-(a)"
  for k,v of hash
    do (k,v)->
      it k, ()->
        scope = new ast.Scope
        a = var_d('a', scope)
        scope.list.push un(a,k)
        assert.equal gen(scope), v
        return
  
  hash =
    ADD           : "(a + b)"
    BOOL_XOR      : "!!(a ^ b)"
    ASS_BOOL_AND  : "(a = !!(a & b))"
    ASS_BOOL_OR   : "(a = !!(a | b))"
    ASS_BOOL_XOR  : "(a = !!(a ^ b))"
  for k,v of hash
    do (k,v)->
      it k, ()->
        scope = new ast.Scope
        a = var_d('a', scope)
        b = var_d('b', scope)
        scope.list.push bin(a,k,b)
        assert.equal gen(scope), v
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
  
  it '{k:a}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Hash_init
    t.hash.k = a
    assert.equal gen(scope), '{"k": a}'
    return
  
  it '{}', ()->
    scope = new ast.Scope
    scope.list.push t = new ast.Struct_init
    assert.equal gen(scope), "{}"
    return
  
  it '{k:a}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    scope.list.push t = new ast.Struct_init
    t.hash.k = a
    assert.equal gen(scope), '{"k": a}'
    return
  
  it '{k:a}', ()->
    scope = new ast.Scope
    a = var_d('a', scope)
    t = new ast.Struct_init
    t.hash.k = a
    
    scope.list.push fa(t, 'k', 'int')
    assert.equal gen(scope), '({"k": a}).k'
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
    
    scope.list.push t = new ast.For_col
    t.v = v
    t.t = a
    t.t.type = new Type 'array<int>'
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
    
    scope.list.push t = new ast.For_col
    t.k = k
    t.v = v
    t.t = a
    t.t.type = new Type 'array<int>'
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
    
    scope.list.push t = new ast.For_col
    t.k = k
    t.t = a
    t.t.type = new Type 'array<int>'
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
    
    scope.list.push t = new ast.For_col
    t.v = v
    t.t = a
    t.t.type = new Type 'hash<int>'
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
    
    scope.list.push t = new ast.For_col
    t.k = k
    t.v = v
    t.t = a
    t.t.type = new Type 'hash<int>'
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
    
    scope.list.push t = new ast.For_col
    t.k = k
    t.t = a
    t.t.type = new Type 'hash<int>'
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
    scope.list.push fnd('fn', new Type('function<void>'), [], [])
    assert.equal gen(scope), 'fn = ()->\n  '
    
  describe 'Class_decl', ()->
    it 'Empty', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      assert.equal gen(scope), """
        class A
          
        
        """
    
    _var_d = (name, _type)->
      t = new ast.Var_decl
      t.name = name
      t.type = new Type _type
      t
    
    it 'Var_decl', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      t.scope.list.push _var_d('a', 'int')
      assert.equal gen(scope), '''
        class A
          a : 0
        
        '''
    
    it 'Var_decl array', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      t.scope.list.push _var_d('a', 'array<int>')
      assert.equal gen(scope), '''
        class A
          a : []
          constructor : ()->
            @a = []
        
        '''
    
    it 'Method', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Class_decl
      t.name = 'A'
      t.scope.list.push fnd('fn', new Type('function<void>'), [], [])
      assert.equal gen(scope), '''
        class A
          fn : ()->
            
        
        '''
  
  describe 'array API', ()->
    it 'remove_idx', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "remove_idx")
      t.arg_list.push ci '1'
      
      assert.equal gen(scope), '''
        ((a).remove_idx)(1)
        '''
    
    it 'length_get', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "length_get")
      
      assert.equal gen(scope), '''
        (a).length
        '''
    
    it 'length_set', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "length_set")
      t.arg_list.push ci '1'
      
      assert.equal gen(scope), '''
        (a).length = 1
        '''
    
    it 'pop', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "pop")
      
      assert.equal gen(scope), '''
        ((a).pop)()
        '''
    
    it 'push', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "push")
      t.arg_list.push ci '1'
      
      assert.equal gen(scope), '''
        ((a).push)(1)
        '''
    
    it 'slice', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "slice")
      t.arg_list.push ci '1'
      t.arg_list.push ci '2'
      
      assert.equal gen(scope), '''
        ((a).slice)(1, 2)
        '''
    
    it 'remove', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "remove")
      t.arg_list.push ci '1'
      
      assert.equal gen(scope), '''
        ((a).remove)(1)
        '''
    
    it 'idx', ()->
      scope = new ast.Scope
      scope.list.push t = new ast.Var_decl
      t.name = 'a'
      t.type = new Type 'array<int>'
      
      scope.list.push t = new ast.Fn_call
      t.fn = fa(_var('a', 'array<int>'), "idx")
      t.arg_list.push ci '1'
      
      assert.equal gen(scope), '''
        ((a).idx)(1)
        '''
    
    describe 'throws', ()->
      it 'wtf method', ()->
        scope = new ast.Scope
        scope.list.push t = new ast.Var_decl
        t.name = 'a'
        t.type = new Type 'array<int>'
        
        scope.list.push t = new ast.Fn_call
        t.fn = fa(_var('a', 'array<int>'), "wtf")
        t.arg_list.push ci '1'
        t.arg_list.push ci '2'
        
        assert.throws ()-> gen(scope)