esglobals = require 'esglobals'

Greenhouse () =
  this.modules = {}
  this

Greenhouse.prototype = {

  resolve (name) =
    detectCircularDependencies (self, name)
    resolveModule (self, name)

  dependenciesOf (name) = dependenciesOf (self, name)

  allDependenciesOf (name) = allDependenciesOf (self, name)

  moduleNames () = Object.keys(self.modules).sort()

  module (definition) =
    unresolveDependants (self, 'greenhouse')
    existingModule = self.modules.(definition.name)
    if (existingModule)
      unresolveDependants (self, definition.name)
      delete (existingModule.resolved)
      delete (existingModule.dependencies)
      existingModule.body = definition.body
    else
      definition.id = nextId ()
      self.modules.(definition.name) = definition

  remove (name) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, name)
    delete (self.modules.(name))

  rename (oldName, newName) =
    unresolveDependants (self, 'greenhouse')
    unresolveDependants (self, oldName)
    existing = self.modules.(oldName)
    delete (self.modules.(oldName))
    existing.name = newName
    self.modules.(newName) = existing

  toString() = "Greenhouse"

}

nextId () =
  nextId.id = (nextId.id @or 0) + 1
  nextId.id

resolveModule (repo, name) =
  target = repo.modules.(name)
  if (target)
    if (!target.resolved)
      resolveTarget (repo, target)

    target.resolved
  else
    @throw @new Error "Module '#(name)' does not exist"

dependenciesOf (repo, name) =
  m = repo.modules.(name)
  if (m)
    if (!m.dependencies @and m.body :: String)
      try
        m.dependencies = esglobals "function _() { #(m.body) }"
      catch (e)
        m.dependencies = []

  (m @and m.dependencies) || []

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
    @throw @new Error("Circular dependency in module '#(name)'")

resolveTarget (repo, target) =
  if (@not target.resolved)

    if (@not target.dependencies)
      target.dependencies = esglobals "function _() { #(target.body) }"

    factory = @new Function(target.dependencies, target.body)
    resolvedDependencies = []
    for each @(dep) in (target.dependencies)
      try
        r = resolveModule (repo, dep)
      catch (e)
        if (e.toString().match(r/Module '.+' does not exist$/))
          @throw @new Error("Dependency '#(dep)' does not exist")
        else
          @throw @new Error("Failed to resolve dependency '#(dep)'")

      resolvedDependencies.push (r)

  target.resolved = factory.apply (null, resolvedDependencies)

unresolveDependants (repo, name) =
  for each @(key) in (Object.keys(repo.modules))
    mod = repo.modules.(key)
    if ((mod.dependencies || []).indexOf(name) > -1)
      delete (mod.resolved)
      unresolveDependants (repo, mod.name)

module.exports = Greenhouse
