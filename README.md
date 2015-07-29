# Greenhouse

A container for JavaScript modules. It's a dependency injection framework,
which sounds bad, but it's actually good.

## Why?

Reloading code when it changes is difficult with `require`. Greenhouse makes it
easy to build reactive interfaces for editing code e.g. in a web browser.

## Modules

To avoid using `require` behaviour at all, Greenhouse assumes that modules are
very small. That way any global variables can be considered as dependencies.
Greenhouse takes charge of interpreting the JavaScript code in each module and
re-interpreting modules when their dependencies are updated.

## Registration

```JavaScript
var Greenhouse = require('greenhouse');

var house = new Greenhouse();

house.module({
  name: 'bomb',
  body: 'clock.atNoon(function() { explode() })'
});

house.module({
  name: 'clock',
  body: 'return { atNoon: function(callback) { callback() } }'
});

house.module({
  name: 'explode',
  body: 'return function() { alert("BANG!") }'
});

house.resolve('bomb'); // -> alerts "BANG!"

house.module({
  name: 'bomb',
  body: 'return clock.atNoon(function() { explode(); explode(); })'
});

house.resolve('bomb'); // -> alerts "BANG!" twice

```

## Doesn't this make a big dirty old global scope? what about namespaces?

Avoid naming collisions by making small modules.

## license

BSD
