_ = require 'lodash'
async = require 'async'
fs = require 'fs'
glob = require 'glob'
ModuleFilterer = require './module_filterer'
path = require 'path'


class ExecutedModulesFinder

  constructor: ({@dir}) ->
    @moduleFilterer = new ModuleFilterer
    {@scripts, dependencies, devDependencies} = require path.join(@dir, 'package.json')
    @scripts ?= {}
    @modulesListed = _.keys(dependencies).concat _.keys(devDependencies)


  find: (done) ->
    @getModuleExecutables (err, moduleExecutables) =>
      if err then return done err
      result = for scriptName, script of @scripts
        moduleNames = @findInScript script, moduleExecutables
        {name: moduleName, scripts: [scriptName]} for moduleName in moduleNames
      done null, _.flatten(result)


  ensureAllModulesInstalled: (moduleExecutables, done) ->
    modulesNotInstalled = _.difference @modulesListed, _.keys(moduleExecutables)
    if modulesNotInstalled.length is 0
      done null, moduleExecutables
    else
      done new Error """
        The following modules are listed in your `package.json` but are not installed.
          #{modulesNotInstalled.join '\n  '}
        All modules need to be installed to properly check for the usage of a module's executables.
        """


  findInScript: (script, moduleExecutables) ->
    result = []
    for moduleName, executables of moduleExecutables
      for executable in executables
        result.push moduleName if script.match(executable) and moduleName not in result
    result = @moduleFilterer.filterExecutedModules result
    result


  getModuleExecutables: (done) ->
    patterns = [
      "#{@dir}/node_modules/*/package.json"
      "#{@dir}/node_modules/*/*/package.json" # scoped packages
    ]
    async.map patterns, glob, (err, files) =>
      if err then return done err
      result = []
      for file in _.flatten files
        {name, bin} = require(file)
        result[name] = _.keys(bin)
      @ensureAllModulesInstalled result, done


module.exports = ExecutedModulesFinder
