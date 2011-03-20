_ = require 'underscore'

class Auf
  constructor: (@depth=Number.MAX_VALUE, @do_all=false) ->

  reduce: (arr, memo, iterator, callback) ->
    return callback(null, memo) unless _.size(arr)

    errs = [] if @do_all
    size = pending = _.size(arr)
    count = 0
    isArray = _.isArray(arr)
    keys = Object.keys(arr) unless isArray

    theCallback = (err, result) ->
      if err
        if errs
          errs.push(err)
        else
          callback(err)
          callback = ->
          return
      else

      if --pending == 0
        err = if errs and errs.length then errs else undefined
        return callback(err,result)
      process(result)

    process = (memo) ->
      if isArray
        val = arr[count++]
        iterator memo, val, theCallback
      else
        key = keys[count++]
        val = arr[key]
        iterator memo, val, key, theCallback

    process(memo)

  each: (arr, iterator, callback, what=0) ->
    return callback() unless _.size(arr)

    if what > 0
      results = []

    errs = [] if @do_all
    workers = 0
    size = pending = _.size(arr)
    concurrency = @depth
    count = 0
    isArray = _.isArray(arr)
    keys = Object.keys(arr) unless isArray

    theCallback = (val,key) ->
      (err, result) ->
        workers -= 1

        if what > 10    # single argument callback
          result = err
          err = null

        if err
          if errs
            errs.push(err)
          else
            callback(err)
            callback = ->
            return
        else
          switch what
            when Auf.MAP then results.push(result)
            when Auf.FILTER then results.push(val) if result
            when Auf.REJECT then results.push(val) unless result

        if --pending == 0
          err = if errs and errs.length then errs else undefined
          return callback(err,results)
        process()

    process = ->
      # console.log("process",pending,concurrency,count,isArray)
      if workers++ < concurrency and count < size
        if isArray
          val = arr[count++]
          iterator val, theCallback(val)
        else
          key = keys[count++]
          val = arr[key]
          iterator val, key, theCallback(val,key)

    process() for i in [1..(if concurrency < pending then concurrency else pending)]

  map: (arr, iterator, callback) ->
    @each arr, iterator, callback, Auf.MAP

  filter: (arr, iterator, callback) ->
    @each arr, iterator, callback, Auf.FILTER

  select: (arr, iterator, callback) ->
    @each arr, iterator, callback, Auf.FILTER

  reject: (arr, iterator, callback) ->
    @each arr, iterator, callback, Auf.REJECT

  queue: (depth) ->
    new Auf(depth, @do_all)

  series: ->
    new Auf(1, @do_all)

  all: ->
    new Auf(@depth, true)

Auf.EACH   = 0
Auf.MAP    = 1
Auf.FILTER = 11
Auf.REJECT = 12
Auf.SOME   = 13
Auf.EVERY  = 14

auf = new Auf()

module.exports = auf
