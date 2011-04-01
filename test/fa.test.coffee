_ = require 'underscore'
fa = require "#{__dirname}/../lib/fa"

suite "fa suite", {serial: false, stopOnFail: true}

timeoutFor = (args) ->
  return (x, cb) ->
    throw new Error("x is undefined") if x==undefined
    setTimeout (() ->
      return cb("Invalid x: #{x}") unless Number(x)
      args.push(x)
      cb(null, x*2)
    ), if Number(x) then x*25 else 0

atest "each", ->
  args = []
  fa.each [1,3,2], timeoutFor(args), (err, result) ->
    t.same undefined, err
    t.same undefined, result
    t.same args, [1,2,3]
    t.done()

atest "series", ->
  args = []
  fa.series().each [1,3,2], timeoutFor(args), (err) ->
    t.same undefined, err
    t.same args, [1,3,2]
    t.done()

["queue","concurrent","c"].forEach (name) ->
  atest name, ->
    args = []
    fa[name](2).each [2,1.5,1], timeoutFor(args), (err) ->
      t.same undefined, err
      t.same args, [1.5,2,1]
      t.done()

test "each empty", ->
  fa.each [], ((x,cb) -> notvalidcode), (err) ->
    t.ok true

test "each error", ->
  fa.each [1,2,3], ((x,cb) -> cb('error')), (err) ->
    t.eq err, 'error'

atest "each continue", ->
  args = []
  fa.continue().each [1,'invalid',3], timeoutFor(args), (err) ->
    t.same [1,3], args
    t.same ['Invalid x: invalid'], err
    t.done()

atest "each continue no error", ->
  args = []
  fa.continue().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,2,3], args
    t.same undefined, err
    t.done()

atest "continue.series.each", ->
  args = []
  fa.continue().series().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.continue.each", ->
  args = []
  fa.series().continue().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.continue.each", ->
  args = []
  fa.series().continue().each [1,3,'invalid'], timeoutFor(args), (err) ->
    t.same [1,3], args
    t.same ['Invalid x: invalid'], err
    t.done()

atest "with_index.each", ->
  args = []
  fa.with_index().each [1,2,3], ((x, i, cb) ->
    t.eq x, i+1
    return cb()
  ), (err) ->
    t.done()

atest "with_index.each object", ->
  args = []
  fa.with_index().each {k1: 1, k2: 2, k3: 3}, ((val, key, i, cb) ->
    t.eq val, i+1
    return cb()
  ), (err) ->
    t.done()

atest "map", ->
  args = []
  fa.map [1,3,2], timeoutFor(args), (err, result) ->
    t.same undefined, err
    t.same result, [2,4,6]
    t.same args, [1,2,3]
    t.done()


["map","concat"].forEach (name) ->
  atest "#{name} empty array", ->
    args = []
    fa[name] [], timeoutFor(args), (err, result) ->
      t.same undefined, err
      t.same result, []
      t.done()

["filter","select"].map (name) ->
  atest name, ->
    args = []
    fa[name] [1,3,2,4], ((x,cb) ->
      return cb(true) if x % 2 == 0
      cb()
    ), (err,results) ->
      t.same results, [2,4]
      t.same undefined, err
      t.done()

atest "reject", ->
  args = []
  fa.reject [1,3,2,4], ((x,cb) ->
    return cb(true) if x % 2 == 0
    cb()
  ), (err,results) ->
    t.same results, [1,3]
    t.same undefined, err
    t.done()

atest "each with object", ->
  args = {}
  fa.each {k1: 1, k2: 2, k3: 3}, ((val,key,cb) ->
    args[val] = key
    cb()
  ), (err) ->
    t.same undefined, err
    t.same args, {1: 'k1', 2: 'k2', 3: 'k3'}
    t.done()

atest "Really deep", ->
  fa.each [x for x in [0..10000]], ((x,cb) ->
    process.nextTick ->
      cb()
  ), (err) ->
    t.same undefined, err
    t.done()

["reduce","foldl","inject"].map (name) ->
  atest name, ->
    fa[name] [1,3,2,4], 0, ((memo, x, cb) -> cb(null, memo + x)), (err, result) ->
      t.same undefined, err
      t.same result, 10
      t.done()

atest "reduce with errs", ->
  fa.reduce [1,3,'oops',4], 0, ((memo, x, cb) ->
    if Number(x)
      cb(null, memo + x)
    else
      cb('oops')
  ), (err, result) ->
    t.same 'oops', err
    t.same undefined, result
    t.done()

atest "continue().reduce with errs", ->
  fa.continue().reduce [1,3,'oops',4], 0, ((memo, x, cb) ->
    if Number(x)
      cb(null, memo + x)
    else
      cb('oops', memo)
  ), (err, result) ->
    t.same ['oops'], err
    t.same 8, result
    t.done()

atest "reduce with obj", ->
  fa.reduce {k1: 1,k2: 3,k3: 2,k4: 4}, 0, ((memo, x, k, cb) -> cb(null, memo + x)), (err, result) ->
    t.same undefined, err
    t.same result, 10
    t.done()

atest "detect", ->
  fa.detect [3,4,2,1], ((x,cb) ->
    setTimeout (() ->
      return cb(true) if x % 2 == 0
      return cb()
    ), x*25
  ), (result, i) ->
    t.same 2, result
    t.same 1, i
    t.done()

atest "detect empty array", ->
  fa.detect [], ((x,cb) ->
  ), (result, i) ->
    t.same undefined, result
    t.same undefined, i
    t.done()

atest "any empty array", ->
  fa.any [], ((x,cb) ->
  ), (result) ->
    t.same false, result
    t.done()

["filter", "reject"].forEach (name) ->
  atest "#{name} empty array", ->
    fa[name] [], ((x,cb) -> ), (result) ->
      t.same [], result
      t.done()

atest "detect series", ->
  fa.series().detect [3,1,4,2,1], ((x,cb) ->
    setTimeout (() ->
      return cb(true) if x % 2 == 0
      cb()
    ), x*25
  ), (result, i) ->
    t.same 4, result
    t.same 2, i
    t.done()

["any","some"].map (name) ->
  atest name, ->
    fa[name] [3,1,2], ((x,cb) ->
      cb(x==1)
    ), (result) ->
      t.eq true, result
      fa[name] [3,4,2], ((x,cb) ->
        cb(x==1)
      ), (result) ->
        t.eq false, result
        t.done()

["all","every"].map (name) ->
  atest name, ->
    fa[name] [3,1,2], ((x, cb) ->
      cb(x < 10)
    ), (result) ->
      t.eq true, result
      fa[name] [3,1,2], ((x, cb) ->
        cb(x < 3)
      ), (result) ->
        t.eq false, result
        t.done()

atest "all empty array", ->
  fa.all [], ((x,cb) ->
  ), (result) ->
    t.same true, result
    t.done()

atest "concat", ->
  fa.concat ['d1','d2'], ((dir, cb) ->
    cb(null, [[1,"#{dir}-1"],[2,"#{dir}-2"]])
  ), (err, results) ->
    t.same [[1,'d1-1'],[2,'d1-2'],[1,'d2-1'],[2,'d2-2']], results
    t.done()

atest "concat with nulls", ->
  fa.concat ['d1',null,'d2'], ((dir, cb) ->
    return cb(null) unless dir
    cb(null, [[1,"#{dir}-1"],[2,"#{dir}-2"]])
  ), (err, results) ->
    t.same [[1,'d1-1'],[2,'d1-2'],[1,'d2-1'],[2,'d2-2']], results
    t.done()

atest "concat queue", ->
  fa.queue(2).concat ['1','2','3','4','5','6'], ((dir, cb) ->
    setTimeout((() ->
      cb(null, ["d#{dir}"])
    ), 50)
  ), (err, results) ->
    t.same ['d1','d2','d3','d4','d5','d6'], results
    t.done()

atest "don't blow stack", ->
  fa.reduce [x for x in [0..10000]][0], 0, ((m,x,cb) -> cb(null, m+x)), (err, memo) ->
    t.equal memo, 50005000
    t.done()

atest "if", ->
  x = null
  fa.if true, ((callback) ->
    x = true
    callback()
  ), (err) ->
    t.ok x
    t.done()

atest "if falsy", ->
  fa.if false, ((cb) -> t.ok false), (err) ->
    t.notError err
    t.done()

atest "if/else", ->
  fa.if true, ((cb) -> cb(null, "one")), ((cb) -> cb(null, "two")), (err, r) ->
    t.notError err
    t.eq r, "one"
    fa.if false, ((cb) -> cb(null, "one")), ((cb) -> cb(null, "two")), (err, r) ->
      t.notError err
      t.eq r, "two"
      t.done()

