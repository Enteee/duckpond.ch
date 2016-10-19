---
layout: post
title: "JavaScript this"
categories: [web]
keywords: [JavaScript, node.js, this, arrow-functions]
---

The following snippet shows how node.js `v6.8.1` sets the `this`-object in various scenarios. I wrote it to solve [this issue](https://stackoverflow.com/questions/40135510/set-this-for-required-arrow-functions) when refactoring [FluentFlow].

```javascript
function requireFromString(src) {
  var Module = module.constructor;
  var m = new Module();
  m._compile(src, __filename);
  return m.exports;
}

(function(){
  var f1 = (() => {console.log(this.a === 1)});
  var f2 = function(){ console.log(this.a === 1) };
  var f3 = requireFromString('module.exports = (() => {console.log(this.a === 1)});');
  var f4 = requireFromString('module.exports = function(){ console.log(this.a === 1) };');

  class c1 { log(){ console.log(this.a === 1) } };
  c2 = requireFromString('module.exports = class c2 { log(){ console.log(this.a === 1) } };');
  class c3 { constructor(log){ this.log = log } }
  c4 = requireFromString('module.exports = class c4 { constructor(log){ this.log = log } };');

  console.log('Body:');
  console.log(this.a === 1);                          // true
  (()=>console.log(this.a === 1))();                  // true
  (()=>console.log(this.a === 1)).call(this);         // true
  (function(){console.log(this.a === 1)})();          // false
  (function(){console.log(this.a === 1)}).call(this); // true

  console.log('\nFunctions:');
  f1();                                               // true
  f1.call(this);                                      // true
  f2();                                               // false
  f2.call(this);                                      // true
  f3();                                               // false
  f3.call(this);                                      // false
  f4();                                               // false
  f4.call(this);                                      // true

  console.log('\nClasses:');
  (new c1).log();                                     // false
  (new c1).log.call(this);                            // true
  (new c2).log();                                     // false
  (new c2).log.call(this);                            // true
  (new c3(f1)).log();                                 // true
  (new c3(f1)).log.call(this);                        // true
  (new c3(f2)).log();                                 // false
  (new c3(f2)).log.call(this);                        // true
  (new c3(f3)).log();                                 // false
  (new c3(f3)).log.call(this);                        // false
  (new c3(f4)).log();                                 // false
  (new c3(f4)).log.call(this);                        // true

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

[FluentFlow]:(https://github.com/t-moe/FluentFlow)
