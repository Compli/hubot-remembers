'use strict'
{ EventEmitter } = require 'events'
path = require 'path'
util = require 'util'

class BrainListener extends EventEmitter
  # The BrainListener constructor listens for the 'saved' and 'loaded' events and 
  # attempts to call the @loadJSON method.
  constructor: (@brainKey, @client, @robot) ->
    console.log('Damnit Jim, the brainKey is', @brainKey)
    listener = @
    @robot.brain.on 'save', (data) ->
      listener.robot.logger.debug("synced on 'save': #{data}")
      listener.sync(data)
    @robot.brain.on 'loaded', (data) ->
      listener.robot.logger.debug("synced on 'loaded':  #{JSON.stringify(data)}")
      listener.sync(data)
    try
      @loadJSON()
    catch e
      @robot.logger.error(e)
  
  # The sync method calls the client.put method to add data passed as the data 
  # argument to etcd, i.e. @cleint.put(@brainKey).value(JSON.stringify(data)
  sync: (data) ->
    listener = @
    @client.put(@brainKey).value(JSON.stringify(data))
      .catch (e) ->
        listener.robot.logger.error("Error with @client.put: #{e}")

  # The loadJSON method calls the client.get method and calls data matching the
  # brainKey.  When the data is loaded, the 'loaded' event is emitted.
  loadJSON: ->
    listener = @
    @client.put(@brainKey).value(JSON.stringify({damn: 'son'}))
    @client.get(@brainKey).string()
      .then (value) ->
        console.log("value was: ", value)
      .catch (e) ->
        listener.robot.logger.error("Error with @client.get: #{e}")
    @emit 'loaded'
    @robot.brain.emit 'loaded'

module.exports = BrainListener
