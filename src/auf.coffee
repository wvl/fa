_ = require 'underscore'


auf = (concurrency=Number.MAX_VALUE, do_all=false) ->
  api = {}

  api.reduce = (arr, memo, iterator, callback) ->
    return callback(null, memo) unless _.size(arr)

    errs = [] if do_all
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

  nullFn = -> undefined

  tmpl = (name, initResults, single_argument_callback, handleResult, handleReturn) ->
    return (arr, iterator, callback, what=0) ->
      return callback() unless _.size(arr)

      results = initResults()

      errs = [] if do_all
      workers = 0
      size = pending = _.size(arr)
      count = 0
      isArray = _.isArray(arr)
      keys = Object.keys(arr) unless isArray
      finished = false

      theCallback = (val,key) ->
        (err, result) ->
          # console.log("callback result", result)
          workers -= 1

          if single_argument_callback
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
            if handleResult(results, result, val, key, callback) == true
              callback = ->
              finished = true
              return

          if --pending == 0
            err = if errs and errs.length then errs else undefined
            if handleReturn
              return handleReturn(err, callback, results, size)
            else
              return callback(err,results)
          process()

      process = ->
        # console.log("process",pending,concurrency,count,isArray)
        if workers++ < concurrency and count < size and !finished
          if isArray
            val = arr[count++]
            iterator val, theCallback(val)
          else
            key = keys[count++]
            val = arr[key]
            iterator val, key, theCallback(val,key)

      process() for i in [1..(if concurrency < pending then concurrency else pending)]

  api.each = tmpl('each',nullFn,false,nullFn)

  # produce a new array of values
  api.map = tmpl('map', (() -> []), false, (results, result) ->
    results.push(result)
  )

  # return an array of values that pass a truth test. alias select
  api.filter = tmpl('filter', (() -> []), true, (results, result, val) ->
    results.push(val) if result
  )

  # return an array of values that the truth test passes. opposite of filter.
  api.reject = tmpl('reject', (() -> []), true, (results, result, val) ->
    results.push(val) unless result
  )

  # first value that passes a truth test
  api.detect = tmpl('detect', (() -> []), true, (results, result, val, key, callback) ->
    if result
      callback(undefined, val)
      true
  )

  # return true if any of the values pass the truth test (short circuits if true is found)
  api.any = tmpl('any', (() -> []), true, ((results, result, val, key, callback) ->
    if result
      callback(true)
      true
  ), (err, callback) ->
    callback(false)
  )

  # return true if all of the values pass the truth test
  api.all = tmpl('all', (() -> []), true, ((results, result, val, key, callback) ->
    results.push(true) if result
  ), (err, callback, results, size) ->
    callback(results.length == size)
  )

  api.queue = (concurrency) ->
    auf(concurrency, do_all)

  api.series = ->
    auf(1, do_all)

  api.continue = ->
    auf(concurrency, true)

  # aliases
  api.select = api.filter
  api.inject = api.reduce
  api.foldl = api.reduce
  api.some = api.any
  api.every = api.all

  api

module.exports = auf()
