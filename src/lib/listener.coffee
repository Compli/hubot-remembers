'use strict'
{ EventEmitter } = require 'events'
{ Etcd } = require 'node-etcd3'
_ = require 'lodash'
syncClient = new Etcd()

class BrainListener extends EventEmitter
  # The BrainListener constructor listens for the 'saved' and events and 
  # attempts to call the @loadJSON method.  If the save event is called by
  # the process.exit event, the constructor attempts to synchronously save
  # the data to etcd.
  constructor: (@brainKey, @client, @robot) ->
    listener = @
    @robot.brain.on 'save', (data) ->
      try
        listener.robot.brain.mergeData(data)
      catch e
        listener.robot.logger.error("Failed to merge data: #{e}")
      try
        listener.robot.logger.debug("Syncing data on 'save': #{JSON.stringify(data)}")
        listener.sync(data)
      catch e
        listener.robot.logger.error("Failed to sync data on 'sav'e: #{e}")
      # When the exit event is triggered, the listener attempts to use the
      # synchronousSync method to prevent the event loop from exiting during save
      process.on 'exit', ->
        try
          listener.synchronousSync(data)
        catch e
          listener.robot.logger.error("Failed to sync data on 'exit': #{e}")
      process.on 'SIGINT', ->
        try
          listener.synchronousSync(data)
        catch e
          listener.robot.logger.error("Failed to sync data on 'SIGINT': #{e}")
      process.on 'SIGTERM', ->
        try
          listener.synchronousSync(data)
        catch e
          listener.robot.logger.error("Failed to sync data on 'SIGTERM': #{e}")
    try
      @loadJSON()
    catch e
      @robot.logger.error(e)
  
  # The sync method calls the client.put method to add data passed as the data 
  # argument to etcd, i.e. @cleint.put(@brainKey).value(JSON.stringify(data)
  sync: (data) ->
    listener = @
    if typeof data == 'object'
      @client.get(@brainKey).string()
        .then (json) ->
          if !_.isEqual(JSON.parse(json), data)
            data = JSON.stringify(data)
            listener.client.put(listener.brainKey).value(data)
              .then (res) ->
                listener.robot.logger.debug("Synced revision #{res.header.revision}: #{data}")
              .catch (e) ->
                listener.robot.logger.error("Unable to sync data: #{e}")
          else
            listener.robot.logger.debug("Aborted Sync: Data did not change")
        .catch (e) ->
          listener.robot.logger.error("Error getting data during sync: #{e}")
    @

  # The synchronousSync method blocks the event loop.  Not recomended for autosave
  # intervals because the user experiance will degrade.  Use when the event loop must
  # be blocked to prevent data loss.  For example, when process.exit is used.
  synchronousSync: (data) ->
    listener = @
    try
      lastrev = syncClient.getSync(listener.brainKey, data)
    catch e
      listener.robot.logger.error("Error getting last revision: #{e}")
    if !_.isEqual(JSON.parse(lastrev), data)
      try
        data = JSON.stringify(data)
      catch e
        listener.robot.logger.error("Error stringifying data: #{e}")
      try
        syncClient.setSync(listener.brainKey, data)
        listener.robot.logger.debug("Synced data on 'exit': #{data}")
      catch e
        listener.robot.logger.debug("Unable to sync data: #{e}")
    else
      listener.robot.logger.debug("Aborted Sync: Data did not change")

  # The loadJSON method calls the client.get method and calls data matching the
  # brainKey.  When the data is loaded, the 'loaded' event is emitted.
  loadJSON: ->
    listener = @
    listener.robot.brain.setAutoSave false
    @client.get(@brainKey).string()
      .then (json) ->
        listener.robot.logger.debug("Got data: #{json}")
        listener.robot.brain.setAutoSave true
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

module.exports = BrainListener
