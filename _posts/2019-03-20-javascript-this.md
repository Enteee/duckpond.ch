---
layout: post
title: "JavaScript: this"
categories: [web]
keywords: [JavaScript, node.js, this, arrow-functions]
---

![Fuck-this.js](/static/posts/javascript-this/fuck-this.jpg)
*Fuck-this.js: A reddit post in [r/ProgrammerHumor](https://www.reddit.com/r/ProgrammerHumor/comments/b252lc/javascript_pain/)*

The snippet below tests if node.js [^1] forwards the `this`-object in various scenarios.
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
  f3();                                               // false [1]
  f3.call(this);                                      // false [2]

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

With the documentation for [this](https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Operators/this) and [arrow functions](https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Functions/Pfeilfunktionen#No_binding_of_this) I can explain all cases except the ones labelled with [1] and [2]. But thanks to the excellent answer by [aaronofleonard](https://stackoverflow.com/users/496606/aaronofleonard) I now understand why:

> The reason is because "fat arrow functions" always take their this lexically, from the surrounding code. They cannot have their this changed with call, bind, etc. Run this code as an example:

```javascript
var object = {
  stuff: 'face',

  append: function() {
    return (suffix) => {
      console.log(this.stuff + ' '+suffix);
    }
  }
}
var object2 = {
  stuff: 'foot'
};

object.append()(' and such');
object.append().call(object2, ' and such');
```

> You will only see `face` and `such`.
> So, as far as why that doesn't work in the case of `f3`, it's because it's a self-contained module being required. Therefore, it's base-level arrow functions will only use the this in the module, they cannot be bound with bind, call, etc etc as discussed. In order to use call on them, they must be regular functions, not arrow functions.
> What does "lexical this" mean? It basically works the same as a closure. Take this code for example:

```javascript
// fileA.js
(function () {
    var info = 'im here!';

    var infoPrintingFunctionA = function() {
        console.log(info);
    };

    var infoPrintingFunctionB = require('./fileB');

    infoPrintingFunctionA();
    infoPrintingFunctionB();
})();
```

```javascript
// fileB.js
module.exports = function() {
    console.log(info);
};
```

> What will be the result? An error, info is not defined. Why? Because the accessible variables (the scope) of a function only includes the variables that are available where the function is defined. Therefore, `infoPrintingFunctionA` has access to info because info exists in the scope where `infoPrintingFunctionA` is defined.
> However, even though `infoPrintingFunctionB` is being called in the same scope, it was not defined in the same scope. Therefore, it cannot access variables from the calling scope.
> But this all has to do with the variables and closures; what about this and arrow functions?
> The this of arrow functions works the same as the closure of other variables in functions. Basically, an arrow function is just saying to include this in the closure that is created. And in the same way you couldn't expect the variables of `fileA` to be accessible to the functions of `fileB`, you can't expect the this of the calling module (`fileA`) to be able to be referenced from the body of the called module (`fileB`).

> TLDR: How do we define "surrounding code", in the expression "lexical this is taken from the surrounding code?" The surrounding code is the scope where the function is defined, not necessarily where it is called.


[^1]: Tested for `v6.8.1` and `v8.15.0`

[FluentFlow]:https://github.com/Enteee/FluentFlow
