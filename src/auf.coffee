_ = require 'underscore'

class Auf
  constructor: (@depth=Number.MAX_VALUE) ->

  each: (arr, iterator, callback) ->
    return callback() unless arr.length

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
            callback(err)
            callback = ->
            return
          return callback() if --pending== 0
          process()
    process() for i in [1..(if concurrency < pending then concurrency else pending)]

    # _.each arr, (x) ->
    #   iterator x, (err) ->
    #     if err
    #       callback(err) if err
    #       callback = ->
    #       return

    #     callback() if --completed == 0

  queue: (depth) ->
    new Auf(depth)

  series: ->
    new Auf(1)

auf = new Auf()

module.exports = auf
