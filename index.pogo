esglobals = require 'esglobals'

Module (definition) =
  this.id = nextId()
  this.name = definition.name
  this.body = definition.body

  if ('resolved' in (definition))
    this.resolved = definition.resolved

  if (definition.dependencies :: Array)
    this.dependencies = definition.dependencies

  this

Module.prototype = {

  parseBody () =
    if (self.body)
      try
        self.dependencies = esglobals "function _() { #(self.body) }"
      catch (e)
        self.dependencies = []
    else
      self.dependencies = []

  toString() = "[Module #(self.name)]"

}

Greenhouse () =
  this.modules = {}
  this

Greenhouse.prototype = {

  resolve (name) =
    detectCircularDependencies (self, name)
    resolveModuleNamed (self, name)

  dependenciesOf (name) = dependenciesOf (self, name)

  dependantsOf (name) = dependantsOf (self, name)

  eventualDependenciesOf (name) = eventualDependenciesOf (self, name)

  eventualDependantsOf (name) = eventualDependantsOf (self, name)

  moduleNames () = Object.keys(self.modules).sort()

  module (definition) = defineModule (self, definition)

  remove (name) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, name)
    delete (self.modules.(name))

  rename (oldName, newName) = renameModule (self, oldName, newName)

  toString() = "Greenhouse"

}

nextId () =
  nextId.id = (nextId.id @or 0) + 1
  nextId.id

defineModule (repo, definition) =
  unresolveDependants (repo, 'greenhouse')
  mod = repo.modules.(definition.name)
  if (mod)
    unresolveDependants (repo, mod.name)
    delete (mod.resolved)
    delete (mod.dependencies)
    mod.body = definition.body
  else
    definition.id = nextId ()
    mod := @new Module(definition)
    repo.modules.(definition.name) = mod

  mod.parseBody()

resolveModuleNamed (repo, name) =
  mod = repo.modules.(name)
  if (mod)
    if (!mod.resolved)
      resolveModule (repo, mod)

    mod.resolved
  else
    @throw @new Error "Module '#(name)' does not exist"

renameModule (repo, oldName, newName) =
  unresolveDependants (repo, 'greenhouse')
  unresolveDependants (repo, oldName)
  existing = repo.modules.(oldName)
  delete (repo.modules.(oldName))
  existing.name = newName
  repo.modules.(newName) = existing

dependantsOf (repo, name) =
  dependants = []
  for each @(key) in (Object.keys(repo.modules))
    mod = repo.modules.(key)
    if ((mod.dependencies || []).indexOf(name) > -1)
      dependants.push (key)

  dependants

eventualDependantsOf (repo, name) =
  deps = []
  stack = [].concat (dependantsOf (repo, name))
  while (stack.length > 0)
    n = stack.shift()
    if (deps.indexOf(n) == -1)
      deps.push (n)
      for each @(d) in (dependantsOf(repo, n))
        stack.push (d)

  deps

dependenciesOf (repo, name) =
  m = repo.modules.(name)
  if (m)
    if (!m.dependencies @and m.body :: String)
      m.parseBody()

  (m @and m.dependencies) || []

eventualDependenciesOf (repo, name) =
  deps = []
  stack = [].concat (dependenciesOf (repo, name))
  while (stack.length > 0)
    n = stack.shift()
    if (deps.indexOf(n) == -1)
      deps.push (n)
      for each @(d) in (dependenciesOf(repo, n))
        stack.push (d)

  deps

detectCircularDependencies (repo, name) =
  if (eventualDependenciesOf (repo, name).indexOf (name) > -1)
    error = @new Error("Circular dependency in module '#(name)'")
    repo.modules.(name).resolved = error
    @throw error

resolveModule (repo, mod) =
  if (@not mod.dependencies)
    mod.parseBody()

  factory = @new Function(mod.dependencies, mod.body)
  resolvedDependencies = []
  for each @(dep) in (mod.dependencies)
    try
      r = resolveModuleNamed (repo, dep)
    catch (e)
      if (e.toString().match(r/Module '.+' does not exist$/))
        nonExistent = @new Error("Dependency '#(dep)' does not exist")
        mod.resolved = nonExistent
        @throw nonExistent
      else
        errored = @new Error("Failed to resolve dependency '#(dep)'")
        mod.resolved = errored
        @throw errored

    resolvedDependencies.push (r)

  mod.resolved = factory.apply (null, resolvedDependencies)

unresolveDependants (repo, name) =
  deps = eventualDependantsOf (repo, name)
  for each @(key) in (deps)
    mod = repo.modules.(key)
    delete (mod.resolved)

module.exports = Greenhouse
