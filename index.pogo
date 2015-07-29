esglobals = require 'esglobals'

Greenhouse () =
  this.modules = {}
  this

Greenhouse.prototype = {

  resolve (name) =
    detectCircularDependencies (self, name)
    resolveModuleNamed (self, name)

  dependenciesOf (name) = dependenciesOf (self, name)

  allDependenciesOf (name) = allDependenciesOf (self, name)

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
  existingModule = repo.modules.(definition.name)
  if (existingModule)
    unresolveDependants (repo, definition.name)
    delete (existingModule.resolved)
    delete (existingModule.dependencies)
    existingModule.body = definition.body
  else
    definition.id = nextId ()
    repo.modules.(definition.name) = definition

  parseModuleDependencies (repo, definition)

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

dependenciesOf (repo, name) =
  m = repo.modules.(name)
  if (m)
    if (!m.dependencies @and m.body :: String)
      parseModuleDependencies(repo, m)

  (m @and m.dependencies) || []

parseModuleDependencies (repo, m) =
  if (m.body)
    try
      m.dependencies = esglobals "function _() { #(m.body) }"
    catch (e)
      m.dependencies = []
  else
    m.dependencies = []

allDependenciesOf (repo, name) =
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
  if (allDependenciesOf (repo, name).indexOf (name) > -1)
    error = @new Error("Circular dependency in module '#(name)'")
    repo.modules.(name).resolved = error
    @throw error

resolveModule (repo, mod) =
  if (@not mod.dependencies)
    parseModuleDependencies (repo, mod)

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
  for each @(key) in (Object.keys(repo.modules))
    mod = repo.modules.(key)
    if ((mod.dependencies || []).indexOf(name) > -1)
      delete (mod.resolved)
      unresolveDependants (repo, mod.name)

module.exports = Greenhouse
