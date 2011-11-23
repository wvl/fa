fa = fluent/functional async
============================

`fa` is a fluent and functional async library. Inspired by async[1] and
underscore[2], it takes the functional operators and adds some modifiers: 
to enable a queue depth, run to completion regardless of errors, run in 
series, and add an index to the callback.

```js
fa.map([1,2,3], 
  function(num,cb) { cb(null, num*2); },
  function(err, result) { console.log(result); }
);

fa.c(10).continue().with_index().map([1,2,3],
  function(num,i,cb) { cb(new Error('')); },
  function(errs, result) { ... }
};
```

## Install

`npm install fa`

## Functions

For all of the following functions, if `list` is a javascript object, 
the iterator signature will be `(value, key, cb)` 
instead of `(element,cb)`.

### **each** `(forEach)`: `fa.each(list, iterator, callback)`

Iterates over a list of elements, yielding each in turn to an iterator
function. The iterator function is called with the `element` and a
`callback`. If an error occurs return it as the first argument to the
iterator callback. The final callback will be called when either all of
the list has been iterated over, or an error occurs. If `list` is a 
javascript object, the iterator signature will 
be `(value, key, cb)`.

```js
fa.each([1,2,3], function(num,cb) {
  // do something with num
  cb(); 
}, function(err) {
  // if (err) { };
})
```

### **map**: `fa.map(list, iterator, callback)`

As in `each`, but build a new list of elements using the iterator
callback.

```js
fa.map([1,2,3], function(num,cb) {
  cb(null, num*2); 
}, function(err, result) {
  // if (err) { };
  assert(result, [2,4,6]);
})
```

### **filter** `(select)`: `fa.filter(list, iterator, callback)`

Iterate through the list, returning all values in the list that
return a *truthy* result from the iterator. **Note** that the
iterator callback should have **only** the *truthy* parameter, **there is no 
error parameter**.

```js
fa.filter([0,1,2,3], function(num,cb) {
  cb(x % 2 == 0); // No Error parameter
}, function(err, result) {
  // result: [0,2]
}
```
### **reject**: `fa.reject(list, iterator, callback)`

The opposite of filter, rejects all values in the list that return
a *truth* result. Again, like **filter**, the iterator callback
should **only** have **one** parameter, **there is no error parameter**.

```js
fa.reject([0,1,2,3], function(num,cb) {
  cb(x % 2 == 0);  // no err parameter
}, function(result) {
  // no err parameter
  // result: [1,3]
}
```

### **detect** `(find)`: `fa.detect(list, iterator, callback)`

Returns the first value where the iterator's callback 
returns a *truthy* result.

```js
fa.detect([1,2,3], function(num, cb) {
  cb(x % 2 == 0);  // no err parameter
}, function(result) {
  // no err parameter
  // result: 2
}
```

### **any** `(some)`: `fa.any(list, iterator, callback)`

Returns true if *any* of the list elements pass the iterator's
truth test.

```js
fa.any([1,2,3], function(num, cb) {
  cb(x % 2 == 0);
}, function(result) {
  // no err parameter
  // result === true
}
```

### **all** `(every)`: `fa.all(list, iterator, callback)`

Returns true if *all* of the list elements pass the iterator's
truth test.

```js
fa.all([2,3,4], function(num, cb) {
  cb(x % 2 == 0);
}, function(result) {
  // no err param
  // result === false
}
```

### **reduce** `(foldl, inject)`: `fa.reduce(list, memo, iterator, callback)`

Boils down a list into a single value. Memo is the initial state of the 
return value. Each successive call to the iterator must return the new
value of memo.

```js
fa.reduce([1,2,3], 0, function(memo, num, cb) {
  cb(null, memo+num);
}, function(err, result) {
  // result === 6
}
```

### **concat**: `fa.concat(list, iterator, callback)`

As in `map`, but concats the results of each iterator together.

```js
fa.concat(['a','b','c'], function(s,cb) {
  cb(null, [s+'0',s+'1']);
}, function(err, result) {
  // result: ['a0','a1','b0','b1','c0','c1']
}
```

*Note* that, unless run in series, the results are not guaranteed
to be in order.

## Modifiers

The default behavior of the functions are:

1. The list is iterated over in parallel. (unless that is 
   impossible, as in the case of `reduce`).
2. The entire list will be queued up immediately.
3. If an error is returned in the iterator's callback, 
   the operation will be terminated immediately.

Each of the modifiers alters the default behavior of each function. 

### **series**: `fa.series().map(...)`

Alter the function to run in series instead of parallel.

### **concurrent** `(c, queue)`: `fa.concurrent(queue_depth).map(...)`

Run only a specified number of operations in parallel. This is useful
if your iterator function is competing over a limited resource, such as
file descriptors.

### **continue**: `fa.continue().map(...)`

If an error is returned from the iterator function, keep going, and collect
all of the errors together. This array of errors is then passed to the final
callback.

```js
fa.continue().map(['file1','file2'], function(filename, cb) {
  fs.read(filename, cb);
}, function(err, result) {
  // if both files are not found, err will be an array of
  // two err objects.
}
```

### **with_index**: `fa.with_index().map(...)`

Adds a loop index variable to the iterator function.

```js
fa.with_index().map(['a','b'], function(elem, i, cb) {
  cb(null, i);
}, function(err, result) {
  // result == [0,1]
}
```

Each of the modifiers can be chained together, in a fluent interface style.
Or, they can be assigned and reused:

```js
var fasc = fa.series().continue();
fasc.map(...);
```


1. [1] https://github.com/caolan/async
2. [2] http://documentcloud.github.com/underscore/


