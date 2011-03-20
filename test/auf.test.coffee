_ = require 'underscore'
auf = require "#{__dirname}/../lib/auf"

timeoutFor = (args) ->
  return (x, cb) ->
    throw new Error("x is undefined") if x==undefined
    setTimeout (() ->
      args.push(x)
      cb()
    ), x*25

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

