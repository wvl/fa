

fa = (concurrency=Number.MAX_VALUE, do_all=false) ->
  api = {}

  api.reduce = (arr, memo, iterator, callback) ->
    isArray = Array.isArray(arr)
    keys = if isArray then arr else Object.keys(arr)
    return callback(undefined, memo) unless keys.length

    errs = [] if do_all
    size = pending = keys.length
    count = 0

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
      isArray = Array.isArray(arr)
      keys = if isArray then arr else Object.keys(arr)
      return callback() unless keys.length

      results = initResults()

      errs = [] if do_all
      workers = 0
      size = pending = keys.length
      count = 0
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
            results = handleResult(results, result, val, key, callback)
            if results == true
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
    results
  )

  # produce a new array of values by concatting results together
  api.concat = tmpl('concat', (() -> []), false, (results, result) ->
    results.concat(result)
  )

  # return an array of values that pass a truth test. alias select
  api.filter = tmpl('filter', (() -> []), true, (results, result, val) ->
    results.push(val) if result
    results
  )

  # return an array of values that the truth test passes. opposite of filter.
  api.reject = tmpl('reject', (() -> []), true, (results, result, val) ->
    results.push(val) unless result
    results
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
  api.all = tmpl('all', (() -> 0), true, ((results, result, val, key, callback) ->
    if result then ++results else results
  ), (err, callback, results, size) ->
    callback(results == size)
  )

  api.queue = (concurrency) ->
    fa(concurrency, do_all)

  api.series = ->
    fa(1, do_all)

  api.continue = ->
    fa(concurrency, true)

  # aliases
  api.forEach = api.each
  api.select  = api.filter
  api.inject  = api.reduce
  api.foldl   = api.reduce
  api.some    = api.any
  api.every   = api.all

  api

module.exports = fa()