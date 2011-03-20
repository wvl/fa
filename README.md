auf = async + underscore + fluent
=================================

I was using [async](https://github.com/calan/async/) a fair bit, and
liking it. I wanted to add queueing capability to the functional async
functions (forEach,map,concat...) so that they would run in parallel,
only up to a certain queue depth. Short of duplicating each of the
functions (again), I figured a fluent interface might be more suitable,
and began experimenting. auf is the result of those experiments.

## Examples

auf.map(['file1','file2'], fs.stat, function(err, results) {
  // results is an array of stats for each file
});

// only run two stats in parallel
auf.queue(2).map(['file1',...], fs.stat, function(err, results) { })

// functionally equivalent to auf.queue(1).map
auf.series.map(['f1','f2',...], fs.stat, function(err, results) {})



