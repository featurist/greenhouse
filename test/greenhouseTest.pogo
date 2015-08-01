expect = require 'chai'.expect
Greenhouse = require '../'

describe 'Greenhouse'

  house = nil
  beforeEach
    house := @new Greenhouse

  it 'resolves modules without dependencies'
    house.module { name = 'x', body = 'return "hello!"' }
    expect(house.resolve 'x').to.equal 'hello!'

  it 'resolves modules with dependencies'
    house.module { name = 'x', body = 'return 123' }
    house.module { name = 'y', body = 'return x + 1' }
    expect(house.resolve 'y').to.equal 124

  it 'finds dependencies without resolving them'
    house.module { name = 'a', body = 'return b + c' }
    expect(house.dependenciesOf 'a').to.eql ['b', 'c']

  it 'finds eventual dependencies without resolving them'
    house.module { name = 'g', body = 'return b + 1' }
    house.module { name = 'a', body = 'return b + c' }
    house.module { name = 'd', body = 'return a + e + g' }
    house.module { name = 'f', body = 'return g + 1' }
    expect(house.eventualDependenciesOf 'd').to.eql ['a', 'c', 'e', 'g', 'b']

  it 'resolves dependencies in new modules'
    house.module { name = 'x', body = 'return 234' }
    house.resolve 'x'
    house.module { name = 'y', body = 'return x + 1' }
    expect(house.resolve 'y').to.equal 235

  it 'resolves new dependencies in redefined modules'
    house.module { name = 'x', body = 'return 1' }
    house.module { name = 'y', body = 'return 2' }
    house.resolve 'y'
    house.module { name = 'y', body = 'return x' }
    y = house.resolve 'y'
    expect(y).to.equal 1

  it 'updates modules without dependencies'
    house.module { name = 'x', body = 'return 666' }
    house.module { name = 'x', body = 'return 777' }
    x = house.resolve 'x'
    expect(x).to.equal 777

  it 'updates modules with dependencies'
    house.module { name = 'x', body = 'return 123' }
    house.module { name = 'y', body = 'return x + 1' }
    house.module { name = 'z', body = 'return y + 1' }
    house.resolve 'z'
    house.module { name = 'x', body = 'return 456' }
    expect(house.resolve 'y').to.equal 457
    expect(house.resolve 'z').to.equal 458

  it 'fails to resolve modules without dependencies'
    resolve () = house.resolve('x')
    expect(resolve).to.throw "Module 'x' does not exist"

  it 'fails to resolve modules with non-existent dependencies'
    house.module { name = 'x', body = 'return 1' }
    house.module { name = 'y', body = 'return z' }
    resolve () = house.resolve('y')
    message = "Dependency 'z' does not exist"
    expect(resolve).to.throw (message)
    expect(house.modules.y.resolved.toString()).to.equal "Error: #(message)"

  it 'fails to resolve modules with dependencies that throw errors'
    house.module { name = 'x', body = 'throw "oops"' }
    house.module { name = 'y', body = 'x + 1' }
    resolve () = house.resolve('y')
    expect(resolve).to.throw "Failed to resolve dependency 'x'"

  it 'fails to resolve modules with dependencies that have syntax errors'
    house.module { name = 'x', body = 'happy =)' }
    house.module { name = 'y', body = 'x + 1' }
    resolve () = house.resolve('y')
    message = "Failed to resolve dependency 'x'"
    expect(resolve).to.throw (message)
    expect(house.modules.y.resolved.toString()).to.equal "Error: #(message)"

  it 'resolves CommonJS modules'
    house.module { name = 'chai', resolved = require 'chai' }
    chai = house.resolve 'chai'
    expect (chai.expect).to.equal (expect)

  it 'resolves CommonJS modules as dependencies'
    house.module { name = 'chai', resolved = require 'chai' }
    house.module { name = 'expect', body = 'return chai.expect' }
    e = house.resolve 'expect'
    expect (e).to.equal (expect)

  describe 'when a module is defined'

    it 'unresolves dependants of the new module'
      house.module { name = 'x', body = 'return y + 1' }
      resolve () = house.resolve 'x'
      expect (resolve).to.throw "Dependency 'y' does not exist"
      house.module { name = 'y', body = 'return 123' }
      expect (resolve()).to.equal 124

  describe 'when a module is removed'

    it 'fails to resolve the module'
      house.module { name = 'x', resolved = Number }
      expect (house.resolve 'x').to.equal (Number)
      house.remove 'x'
      resolve () = house.resolve('x')
      expect(resolve).to.throw "Module 'x' does not exist"

    it 'fails to resolve dependant modules'
      house.module { name = 'x', resolved = 123 }
      house.module { name = 'y', body = 'return x + 1' }
      expect(house.resolve 'y').to.equal 124
      house.remove 'x'
      resolve () = house.resolve('y')
      expect(resolve).to.throw "Dependency 'x' does not exist"

    it 'unresolves dependants of "greenhouse"'
      house.module { name = 'x', body = 'return 101' }
      house.module { name = 'greenhouse', resolved = house }
      house.module { name = 'y', body = 'return greenhouse.resolve("x")' }
      expect(house.resolve('y')).to.equal 101
      house.remove 'x'
      resolve () = house.resolve('y')
      expect(resolve).to.throw "Module 'x' does not exist"

  describe 'when a module is renamed'

    it 'retains the module id'
      house.module { name = 'x', resolved = 42 }
      id = house.modules.x.id
      house.rename 'x' 'y'
      expect (house.modules.y.id).to.equal (id)

    it 'can be resolved by the new name'
      house.module { name = 'x', resolved = 84 }
      house.rename 'x' 'y'
      expect (house.resolve 'y').to.equal 84

    it 'cannot be resolved by the old name'
      house.module { name = 'x', resolved = 999 }
      house.rename 'x' 'y'
      threw = 'nothing thrown'
      resolve () = house.resolve 'x'
      expect(resolve).to.throw "Module 'x' does not exist"

    it 'unresolves dependants of "greenhouse"'
      house.module { name = 'x', body = 'return 111' }
      house.module { name = 'greenhouse', resolved = house }
      house.module { name = 'y', body = 'return greenhouse.resolve("x")' }
      house.resolve 'x'
      house.rename 'x' 'z'
      resolve () = house.resolve 'y'
      expect(resolve).to.throw "Module 'x' does not exist"
      expect(typeof (house.resolve 'greenhouse')).to.equal 'object'

  describe 'when a module is redefined'

    it 'retains the module id'
      house.module { name = 'x', body = 'return 1' }
      id = house.modules.x.id
      house.module { name = 'x', body = 'return 2' }
      expect (house.modules.x.id).to.equal (id)

    it 'updates the modules dependencies'
      house.module { name = 'x', body = 'return 1' }
      house.module { name = 'y', body = 'return 2' }
      house.resolve 'y'
      house.module { name = 'y', body = 'return x' }
      expect (house.dependenciesOf('y')).to.eql(['x'])

    it 'unresolves dependants of "greenhouse"'
      house.module { name = 'x', body = 'return 888' }
      house.module { name = 'greenhouse', resolved = house }
      house.module { name = 'y', body = 'return greenhouse.resolve("x")' }
      expect(house.resolve('y')).to.equal 888
      house.module { name = 'x', body = 'return 777' }
      expect(house.resolve('y')).to.equal 777
      expect(typeof (house.resolve 'greenhouse')).to.equal 'object'

  describe 'when a module refers to itself directly'

    it 'enumerates the modules dependants'
      house.module { name = 'x', body = 'return x' }
      expect(house.dependantsOf('x')).to.eql ['x']

    it 'enumerates the modules eventual dependants'
      house.module { name = 'x', body = 'return x' }
      expect(house.eventualDependantsOf('x')).to.eql ['x']

    it 'fails to resolve the module'
      house.module { name = 'x', body = 'return x' }
      resolve () = house.resolve('x')
      message = "Circular dependency in module 'x'"
      expect(resolve).to.throw (message)
      expect(house.modules.x.resolved.toString()).to.equal "Error: #(message)"

    it 'allows the module to be updated'
      house.module { name = 'x', body = 'return x + 1' }
      resolve () = house.resolve('x')
      expect(resolve).to.throw
      house.module { name = 'x', body = 'return 1' }
      expect(resolve()).to.equal 1

  describe 'when a module eventually depends on itself'

    it 'enumerates the modules dependants'
      house.module { name = 'x', body = 'return y' }
      house.module { name = 'y', body = 'return x' }
      expect(house.dependantsOf('x')).to.eql ['y']
      expect(house.dependantsOf('y')).to.eql ['x']

    it 'enumerates the modules eventual dependants'
      house.module { name = 'x', body = 'return z' }
      house.module { name = 'y', body = 'return x' }
      house.module { name = 'z', body = 'return y' }
      expect(house.eventualDependantsOf('x')).to.eql ['z', 'x', 'y']
      expect(house.eventualDependantsOf('y')).to.eql ['x', 'y', 'z']
      expect(house.eventualDependantsOf('z')).to.eql ['y', 'z', 'x']

    it 'fails to resolve the module'
      house.module { name = 'x', body = 'return y' }
      house.module { name = 'y', body = 'return x' }
      resolve () = house.resolve('x')
      message = "Circular dependency in module 'x'"
      expect(resolve).to.throw (message)
      expect(house.modules.x.resolved.toString()).to.equal "Error: #(message)"

    it 'allows the module to be updated'
      house.module { name = 'x', body = 'return y' }
      house.module { name = 'y', body = 'return x' }
      resolve () = house.resolve('x')
      expect(resolve).to.throw
      house.module { name = 'x', body = 'return 1' }
      expect(resolve()).to.equal 1
