_ = require 'underscore'
auf = require "#{__dirname}/../lib/auf"

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
  auf.queue(2).each [1.5,1,1], timeoutFor(args), (err) ->
    t.same undefined, err
    t.same args, [1,1.5,1]
    t.done()

test "each empty", ->
  auf.each [], ((x,cb) -> notvalidcode), (err) ->
    t.ok true

test "each error", ->
  auf.each [1,2,3], ((x,cb) -> cb('error')), (err) ->
    t.eq err, 'error'

atest "each all", ->
  args = []
  auf.all().each [1,'invalid',3], timeoutFor(args), (err) ->
    t.same [1,3], args
    t.same ['Invalid x: invalid'], err
    t.done()

atest "each all no error", ->
  args = []
  auf.all().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,2,3], args
    t.same undefined, err
    t.done()

atest "all.series.each", ->
  args = []
  auf.all().series().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.all.each", ->
  args = []
  auf.series().all().each [1,3,2], timeoutFor(args), (err) ->
    t.same [1,3,2], args
    t.same undefined, err
    t.done()

atest "series.all.each", ->
  args = []
  auf.series().all().each [1,3,'invalid'], timeoutFor(args), (err) ->
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

atest "filter", ->
  args = []
  auf.filter [1,3,2,4], ((x,cb) ->
    return cb(true) if x % 2 == 0
    cb()
  ), (err,results) ->
    t.same results, [2,4]
    t.same undefined, err
    t.done()

atest "select", ->
  args = []
  auf.select [1,3,2,4], ((x,cb) ->
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
