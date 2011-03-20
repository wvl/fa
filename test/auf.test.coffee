_ = require 'underscore'
auf = require "#{__dirname}/../lib/auf"

timeoutFor = (args) ->
  return (x, cb) ->
    throw new Error("x is undefined") if x==undefined
    setTimeout (() ->
      return cb("Invalid x: #{x}") if x.toString().match(/invalid/)
      args.push(x)
      cb()
    ), if x == 'invalid' then 0 else x*25

atest "each", ->
  args = []
  auf.each [1,3,2], timeoutFor(args), (err) ->
    t.same undefined, err
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
