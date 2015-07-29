expect = require 'chai'.expect
Greenhouse = require '../'

describe 'Greenhouse'

  it 'supports TDD'

    house = @new Greenhouse
    house.module {
      name = 'greenhouse'
      resolved = house
    }
    house.module {
      name = 'console'
      resolved = console
    }
    house.module {
      name = 'allTests'
      body = "return findAllTests.map(function(m) {
                return [m, resolve(m)] })
             "
    }
    house.module {
      name = 'resolve'
      body = "return function(name) {
                     try { return greenhouse.resolve(name) }
                     catch(e) { return ['ERROR', e.toString()] }
              }
             "
    }
    house.module {
      name = 'expect'
      resolved = expect
    }
    house.module {
      name = 'String'
      resolved = String
    }
    house.module {
      name = 'exampleTest'
      body = "return test(function() { expect('sausages').to.equal('eggs'); });"
    }
    house.module {
      name = 'secondTest'
      body = "return test(function() { expect('eggs').to.equal('eggs'); });"
    }
    house.module {
      name = 'findAllTests'
      body = "return greenhouse.moduleNames().filter(function(name) {
                return greenhouse.allDependenciesOf(name).indexOf('test') > -1; });
             "
    }
    house.module {
      name = 'test'
      body = "return function(fn) {
                 try { fn() }
                 catch(e) { return ['FAIL', e.toString()] }
                 return 'PASS' }"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', [ 'FAIL', "AssertionError: expected 'sausages' to equal 'eggs'" ] ]
      [ 'secondTest', 'PASS' ]
    ]
    house.module {
      name = 'exampleTest'
      body = "return test(function() { expect('sausages').to.equal('sausages'); });"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', 'PASS' ]
      [ 'secondTest', 'PASS' ]
    ]
    house.module {
      name = 'exampleTest'
      body = "return test(function() { expect('x').to.equal('x'); });"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', 'PASS' ]
      [ 'secondTest', 'PASS' ]
    ]
    house.module {
      name = 'test'
      body = "return function(fn) {
                 try { fn() }
                 catch(e) { return ['FAIL', e.toString()] }
                 return 'PASS!' }"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', 'PASS!' ]
      [ 'secondTest', 'PASS!' ]
    ]
    house.module {
      name = 'thirdTest'
      body = "return test(function() { expect('z').to.equal('x'); });"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', 'PASS!' ]
      [ 'secondTest', 'PASS!' ]
      [ 'thirdTest', ['FAIL', "AssertionError: expected 'z' to equal 'x'"] ]
    ]
    house.module {
      name = 'thirdTest'
      body = "return test(function() { thirdTest() });"
    }
    expect(house.resolve 'allTests').to.eql [
      [ 'exampleTest', 'PASS!' ]
      [ 'secondTest', 'PASS!' ]
      [ 'thirdTest', ['ERROR', "Error: Circular dependency in module 'thirdTest'"] ]
    ]
