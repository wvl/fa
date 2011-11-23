fa = fluent/functional async
============================

`fa` is a fluent and functional async library. Inspired by async[1], it
takes the functional operators, and adds some modifiers, to enable a
queue depth, run to completion regardless of errors, run in series, and
add an index to the callback.

```js
fa.map(
  [1,2,3], 
  function(num,cb) { cb(null, num*2); },
  function(err, result) { console.log(result); }
);
```

[1] https://github.com/caolan/async


