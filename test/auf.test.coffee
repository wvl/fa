_ = require 'underscore'
auf = require "#{__dirname}/../lib/auf"

suite "auf suite", {serial: false, stopOnFail: true}

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
  auf.each [1,3,2], timeoutFor(args), (err, result) ->
    t.same undefined, err
    t.same undefined, result
    t.same args, [1,2,3]
    t.done()

atest "series", ->
  args = []
  auf.series().each [1,3,2], timeoutFor(args), (err) ->
    t.same undefined, err
    t.same args, [1,3,2]
    t.done()

atest "queue", ->
  args = []
  auf.queue(2).each [2,1.5,1], timeoutFor(args), (err) ->
    t.same undefined, err
    t.same args, [1.5,2,1]
    t.done()

test "each empty", ->
  auf.each [], ((x,cb) -> notvalidcode), (err) ->
    t.ok true

test "each error", ->
  auf.each [1,2,3], ((x,cb) -> cb('error')), (err) ->
    t.eq err, 'error'

atest "each continue", ->
  args = []
  auf.continue().each [1,'invalid',3], timeoutFor(args), (err) ->
    t.same [1,3], args
    t.same ['Invalid x: invalid'], err
    t.done()

atest "each continue no error", ->
  args = []
  auf.continue().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,2,3], args
    t.same undefined, err
    t.done()

atest "continue.series.each", ->
  args = []
  auf.continue().series().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.continue.each", ->
  args = []
  auf.series().continue().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.continue.each", ->
  args = []
  auf.series().continue().each [1,3,'invalid'], timeoutFor(args), (err) ->
    t.same [1,3], args
    t.same ['Invalid x: invalid'], err
    t.done()

atest "map", ->
  args = []
  auf.map [1,3,2], timeoutFor(args), (err, result) ->
    t.same undefined, err
    t.same result, [2,4,6]
    t.same args, [1,2,3]
    t.done()

["filter","select"].map (name) ->
  atest name, ->
    args = []
    auf[name] [1,3,2,4], ((x,cb) ->
      return cb(true) if x % 2 == 0
      cb()
    ), (err,results) ->
      t.same results, [2,4]
      t.same undefined, err
      t.done()

atest "reject", ->
  args = []
  auf.reject [1,3,2,4], ((x,cb) ->
    return cb(true) if x % 2 == 0
    cb()
  ), (err,results) ->
    t.same results, [1,3]
    t.same undefined, err
    t.done()

atest "each with object", ->
  args = {}
  auf.each {k1: 1, k2: 2, k3: 3}, ((val,key,cb) ->
    args[val] = key
    cb()
  ), (err) ->
    t.same undefined, err
    t.same args, {1: 'k1', 2: 'k2', 3: 'k3'}
    t.done()

atest "Really deep", ->
  auf.each [x for x in [0..10000]], ((x,cb) ->
    process.nextTick ->
      cb()
  ), (err) ->
    t.same undefined, err
    t.done()

["reduce","foldl","inject"].map (name) ->
  atest name, ->
    auf[name] [1,3,2,4], 0, ((memo, x, cb) -> cb(null, memo + x)), (err, result) ->
      t.same undefined, err
      t.same result, 10
      t.done()

atest "reduce with errs", ->
  auf.reduce [1,3,'oops',4], 0, ((memo, x, cb) ->
    if Number(x)
      cb(null, memo + x)
    else
      cb('oops')
  ), (err, result) ->
    t.same 'oops', err
    t.same undefined, result
    t.done()

atest "continue().reduce with errs", ->
  auf.continue().reduce [1,3,'oops',4], 0, ((memo, x, cb) ->
    if Number(x)
      cb(null, memo + x)
    else
      cb('oops', memo)
  ), (err, result) ->
    t.same ['oops'], err
    t.same 8, result
    t.done()

atest "reduce with obj", ->
  auf.reduce {k1: 1,k2: 3,k3: 2,k4: 4}, 0, ((memo, x, k, cb) -> cb(null, memo + x)), (err, result) ->
    t.same undefined, err
    t.same result, 10
    t.done()

atest "detect", ->
  auf.detect [3,2,1,4], ((x,cb) ->
    setTimeout (() ->
      return cb(true) if x % 2 == 0
      cb()
    ), x*25
  ), (err,result) ->
    t.same undefined, err
    t.same 2, result
    t.done()

["any","some"].map (name) ->
  atest name, ->
    auf[name] [3,1,2], ((x,cb) ->
      cb(x==1)
    ), (result) ->
      t.eq true, result
      auf[name] [3,4,2], ((x,cb) ->
        cb(x==1)
      ), (result) ->
        t.eq false, result
        t.done()

["all","every"].map (name) ->
  atest name, ->
    auf[name] [3,1,2], ((x, cb) ->
      cb(x < 10)
    ), (result) ->
      t.eq true, result
      auf[name] [3,1,2], ((x, cb) ->
        cb(x < 3)
      ), (result) ->
        t.eq false, result
        t.done()

atest "concat is a simple map away", ->
  auf.map ['d1','d2'], ((dir, cb) ->
    cb(null, ["#{dir}-1","#{dir}-2"])
  ), (err, results) ->
    t.same ['d1-1','d1-2','d2-1','d2-2'], _.flatten(results)
    t.done()
