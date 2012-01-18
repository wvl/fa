

fa = (concurrency=Number.MAX_VALUE, do_all=false, with_index=false) ->
  process ?= {}
  process.nextTick ?= (cb) ->
    cb()

  api = {}

  api.reduce = (arr, memo, iterator, callback) ->
    isArray = Array.isArray(arr)
    try
      keys = if isArray then arr else Object.keys(arr)
    catch e
      return callback(new Error("Trying to reduce over non iterable"))
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

      process.nextTick -> # use nextTick to avoid blowing the call stack
        nextItem(result)

    nextItem = (memo) ->
      if isArray
        val = arr[count++]
        iterator memo, val, theCallback
      else
        key = keys[count++]
        val = arr[key]
        iterator memo, val, key, theCallback

    nextItem(memo)

  nullFn = -> undefined

  tmpl = (name, initResults, single_argument_callback, handleResult, handleReturn) ->
    return (arr, iterator, callback, what=0) ->
      isArray = Array.isArray(arr)
      keys = if isArray then arr else Object.keys(arr)

      results = initResults()
      if !keys.length
        if single_argument_callback
          return callback(results)
        else
          return callback(undefined, results)

      errs = [] if do_all
      workers = 0
      size = pending = keys.length
      count = 0
      finished = false

      theCallback = (val,index) ->
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
            results = handleResult(results, result, val, index, callback)
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
          process.nextTick ->
            nextItem()

      nextItem = ->
        # console.log("process",pending,concurrency,count,isArray)
        if workers++ < concurrency and count < size and !finished
          index = count++
          if isArray
            val = arr[index]
            if with_index
              iterator val, index, theCallback(val, index)
            else
              iterator val, theCallback(val, index)
          else
            key = keys[index]
            val = arr[key]
            if with_index
              iterator val, key, index, theCallback(val,index)
            else
              iterator val, key, theCallback(val,index)

      nextItem() for i in [1..(if concurrency < pending then concurrency else pending)]

  api.each = tmpl('each',nullFn,false,nullFn)

  # produce a new array of values
  api.map = tmpl('map', (() -> []), false, (results, result, val, index) ->
    results[index] = result
    results
  )

  # produce a new array of values by concatting results together
  api.concat = tmpl('concat', (() -> []), false, (results, result) ->
    if Array.isArray(result) then results.concat(result) else results
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
  api.detect = tmpl('detect', (() -> undefined), true, (results, result, val, index, callback) ->
    results = 0 if results==undefined
    if result
      callback(val, results)
      return true
    ++results
  )

  # return true if any of the values pass the truth test (short circuits if true is found)
  api.any = tmpl('any', (() -> false), true, ((results, result, val, index, callback) ->
    if result
      callback(true)
      true
  ), (err, callback) ->
    callback(false)
  )

  # return true if all of the values pass the truth test
  api.all = tmpl('all', (() -> true), true, ((results, result, val, index, callback) ->
    results = 0 if results==true
    if result then ++results else results
  ), (err, callback, results, size) ->
    callback(results == size)
  )

  #
  # Moderator functions -- modify how the iterators behave
  #
  api.queue = (concurrency) ->
    fa(concurrency, do_all, with_index)

  api.series = ->
    fa(1, do_all, with_index)

  api.with_index = ->
    fa(concurrency, do_all, true)

  api.continue = ->
    fa(concurrency, true, with_index)

  # aliases
  api.forEach = api.each
  api.select  = api.filter
  api.find    = api.detect
  api.inject  = api.reduce
  api.foldl   = api.reduce
  api.some    = api.any
  api.every   = api.all

  api.concurrent = api.queue
  api.c          = api.queue


  api.if = (conditional, trueFn, elseFn, callback) ->
    if !callback
      callback = elseFn
      elseFn = null

    if conditional
      trueFn callback 
    else
      if elseFn
        elseFn callback
      else
        callback()

  api

if typeof(module) != 'undefined'
  module.exports = fa()
else
  window.fa = fa()
