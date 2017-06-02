'use strict'
{ EventEmitter } = require 'events'

class BrainListener extends EventEmitter
  # The BrainListener constructor listens for the 'saved' and 'loaded' events and 
  # attempts to call the @loadJSON method.
  constructor: (@brainKey, @client, @robot) ->
    listener = @
    @robot.brain.on 'save', (data) ->
      listener.robot.logger.debug("Syncing data on 'save': #{JSON.stringify(data)}")
      listener.sync(data)
    @robot.brain.on 'loaded', (data) ->
      listener.robot.logger.debug("Syncing data on 'loaded':  #{JSON.stringify(data)}")
      listener.sync(data)
    try
      @loadJSON()
      setTimeout ->
        listener.loadJSON()
      , 10000
    catch e
      @robot.logger.error(e)
  
  # The sync method calls the client.put method to add data passed as the data 
  # argument to etcd, i.e. @cleint.put(@brainKey).value(JSON.stringify(data)
  sync: (data = {}) ->
    listener = @
    if typeof data == 'object' or typeof data == 'string' or typeof data == 'array'
      try
        data = JSON.stringify(data)
      catch e
        listener.robot.logger.error("Unable to parse json: #{e}")
      listener.robot.logger.debug("Syncing: #{data}")
      @client.put(@brainKey).value(data)
        .then (res) ->
          listener.emit 'synced'
          listener.robot.logger.debug("Synced revision #{res.header.revision}: #{data}")
        .catch (e) ->
          listener.robot.logger.error("Unable to sync data: #{e}")
    else
      listener.robot.logger.error("Data must be an object, string, or array")
    @

  # The loadJSON method calls the client.get method and calls data matching the
  # brainKey.  When the data is loaded, the 'loaded' event is emitted.
  loadJSON: ->
    listener = @
    @client.get(@brainKey).string()
      .then (json) ->
        listener.robot.logger.debug("Got data: #{json}")
        try
          data = JSON.parse(json)
        catch e
          listener.robot.logger.error("Unable to parse json: #{e}")
        try
          listener.robot.logger.debug("Merging data: #{JSON.stringify(data)}")
          listener.robot.brain.mergeData(data)
        catch e
          listener.robot.logger.error("Unable to merge data: #{e}")
      .catch (e) ->
        listener.robot.logger.error("Unable to get data: #{e}")
    @emit 'loaded'

module.exports = BrainListener
