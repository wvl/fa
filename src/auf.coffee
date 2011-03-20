_ = require 'underscore'

class Auf
  constructor: (@depth=Number.MAX_VALUE, @do_all=false) ->

  each: (arr, iterator, callback) ->
    return callback() unless arr.length

    errs = [] if @do_all
    workers = 0
    pending = arr.length
    concurrency = @depth
    count = 0

    process = ->
      # console.log("process",pending,concurrency,count)
      if workers++ < concurrency and count < arr.length
        iterator arr[count++], (err) ->
          workers -= 1
          if err
            if errs
              errs.push(err)
            else
              callback(err)
              callback = ->
              return
          return callback(if errs and errs.length then errs else undefined) if --pending== 0
          process()
    process() for i in [1..(if concurrency < pending then concurrency else pending)]

  queue: (depth) ->
    new Auf(depth, @do_all)

  series: ->
    new Auf(1, @do_all)

  all: ->
    new Auf(@depth, true)

auf = new Auf()

module.exports = auf
