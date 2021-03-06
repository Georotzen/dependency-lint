_ = require 'lodash'
{builtInModules, globalModules} = require '../module_db'


class ModuleFilterer

  filterExecutedModules: (moduleNames) ->
    _.chain(moduleNames)
      .filter (name) ->
        name not in globalModules
      .value()


  filterRequiredModules: (moduleNames) ->
    _.chain(moduleNames)
      .filter (name) ->
        name[0] isnt '.' and
        name not in builtInModules
      .map (name) ->
        parts = name.split '/'
        if name[0] is '@'
          parts.slice(0, 2).join '/'
        else
          parts[0]
      .value()


module.exports = ModuleFilterer
