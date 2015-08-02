esglobals = require 'esglobals'

Module (definition) =
  this.name = definition.name

  if ('resolved' in (definition))
    this.resolved = definition.resolved
    this.dependencies = []
  else if ('body' in (definition))
    this.body = definition.body
    this.parseBody ()

  this.id = Module.nextId || 0
  Module.nextId = this.id + 1
  this

Module.prototype = {

  resolve (repo) =
    resolvedDependencies = self.dependencies.map @(name)
      self.resolveDependency (repo, name)

    factory = @new Function(self.dependencies, self.body)
    self.resolved = factory.apply (null, resolvedDependencies)

  resolveDependency (repo, name) =
    try
      r = repo.resolve (name)
    catch (e)
      if (e.noSuchModule)
        nonExistent = @new Error("Dependency '#(name)' does not exist")
        self.resolved = nonExistent
        @throw nonExistent
      else
        errored = @new Error("Failed to resolve dependency '#(name)'")
        self.resolved = errored
        @throw errored

  unresolve () =
    delete (self.resolved)

  parseBody () =
    if (self.body)
      try
        self.dependencies = esglobals "function _() { #(self.body) }"
      catch (e)
        self.dependencies = []
    else
      self.dependencies = []

  updateBody (body) =
    delete (self.resolved)
    delete (self.dependencies)
    self.body = body
    self.parseBody ()

  toString() = "[Module #(self.name)]"

}

Greenhouse () =
  this.modules = {}
  this.moduleList = []
  this

Greenhouse.prototype = {

  resolve (name) =
    detectCircularDependencies (self, name)
    mod = self.modules.(name)
    if (mod)
      mod.resolved = mod.resolved @or mod.resolve (self)
    else
      e = @new Error "Module '#(name)' does not exist"
      e.noSuchModule = true
      @throw e

  dependenciesOf (name) =
    m = self.modules.(name)
    (m @and m.dependencies) @or []

  dependantsOf (name) =
    [
      mod <- self.moduleList
      mod.dependencies
      mod.dependencies.indexOf (name) > -1
      mod.name
    ]

  eventualDependenciesOf (name) =
    walk (name) @(n)
      self.dependenciesOf (n)

  eventualDependantsOf (name) =
    walk (name) @(n)
      self.dependantsOf (n)

  moduleNames () =
    Object.keys(self.modules).sort()

  module (definition) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, definition.name)
    mod = self.modules.(definition.name)
    if (mod)
      mod.updateBody (definition.body)
    else
      newModule = @new Module (definition)
      self.modules.(definition.name) = newModule
      self.moduleList.push (newModule)

  remove (name) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, name)
    delete (self.modules.(name))
    self.moduleList = [m <- self.moduleList, m.name != name, m]

  rename (oldName, newName) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, oldName)
    existing = self.modules.(oldName)
    delete (self.modules.(oldName))
    existing.name = newName
    self.modules.(newName) = existing

  toString() = "Greenhouse"

}

lastUnique (value, index, array) = array.lastIndexOf(value) == index

walk (first, more) =
  result = []
  walked = {}
  stack = [].concat (more(first))
  while (stack.length > 0)
    n = stack.shift ()
    result.push (n)
    rest = more (n)
    for each @(r) in (rest)
      if (stack.indexOf(r) == -1 @and r != first @and (@not walked.(n)))
        stack.push (r)

      result.push (r)

    walked.(n) = true  

  result.filter(lastUnique)

detectCircularDependencies (repo, name) =
  if (repo.eventualDependenciesOf (name).indexOf (name) > -1)
    error = @new Error("Circular dependency in module '#(name)'")
    repo.modules.(name).resolved = error
    @throw error

unresolveDependants (repo, name) =
  [
    d <- repo.eventualDependantsOf (name)
    repo.modules.(d).unresolve()
  ]

module.exports = Greenhouse
