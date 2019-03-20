---
layout: post
title: "JavaScript: this"
categories: [web]
keywords: [JavaScript, node.js, this, arrow-functions]
---

{%
  responsive_image
  path: static/posts/javascript-this/fuck-this.jpg
  caption: 'Fuck-this.js'
%}

The snippet below tests if node.js [^1] forwards the `this`-objects in various scenarios.
I wrote it to solve [this issue](https://stackoverflow.com/questions/40135510/set-this-for-required-arrow-functions) when refactoring [FluentFlow].

If you can think of any unintuitive handling of the `this`-object in JavaScript please share a snippet in the comment section.

```javascript
/**
 * Helper to require a module from a string
 */
function requireFromString(src) {
  var Module = module.constructor;
  var m = new Module();
  m._compile(src, __filename);
  return m.exports;
}

(function(){

  console.log('Body:');

  console.log(this.a === 1);                          // true
  (()=>console.log(this.a === 1))();                  // true
  (()=>console.log(this.a === 1)).call(this);         // true
  (function(){console.log(this.a === 1)})();          // false
  (function(){console.log(this.a === 1)}).call(this); // true

  console.log('\nFunctions:');

  var f1 = (() => {console.log(this.a === 1)});
  f1();                                               // true
  f1.call(this);                                      // true

  var f2 = function(){ console.log(this.a === 1) };
  f2();                                               // false
  f2.call(this);                                      // true

  var f3 = requireFromString('module.exports = (() => {console.log(this.a === 1)});');
  f3();                                               // false
  f3.call(this);                                      // false

  var f4 = requireFromString('module.exports = function(){ console.log(this.a === 1) };');
  f4();                                               // false
  f4.call(this);                                      // true

  console.log('\nClasses:');

  class c1 { log(){ console.log(this.a === 1) } };
  (new c1).log();                                     // false
  (new c1).log.call(this);                            // true

  c2 = requireFromString('module.exports = class c2 { log(){ console.log(this.a === 1) } };');
  (new c2).log();                                     // false
  (new c2).log.call(this);                            // true

  class c3 { constructor(log){ this.log = log } }
  (new c3(f1)).log();                                 // true
  (new c3(f1)).log.call(this);                        // true
  (new c3(f2)).log();                                 // false
  (new c3(f2)).log.call(this);                        // true
  (new c3(f3)).log();                                 // false
  (new c3(f3)).log.call(this);                        // false
  (new c3(f4)).log();                                 // false
  (new c3(f4)).log.call(this);                        // true

  c4 = requireFromString('module.exports = class c4 { constructor(log){ this.log = log } };');
  (new c4(f1)).log();                                 // true
  (new c4(f1)).log.call(this);                        // true
  (new c4(f2)).log();                                 // false
  (new c4(f2)).log.call(this);                        // true
  (new c4(f3)).log();                                 // false
  (new c4(f3)).log.call(this);                        // false
  (new c4(f4)).log();                                 // false
  (new c4(f4)).log.call(this);                        // true
}).apply({a:1});
```

[^1]: Tested for `v6.8.1` and `v8.15.0`

[FluentFlow]:https://github.com/Enteee/FluentFlow
