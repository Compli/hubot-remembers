'use strict'
_ = require 'lodash'
deasyncPromise = require 'deasync-promise'

class BrainListener
  # The BrainListener constructor listens for the 'saved' and events and 
  # attempts to call the @loadJSON method.  If the save event is called by
  # the process.exit event, the constructor attempts to synchronously save
  # the data to etcd.
  constructor: (@brainKey, @client, @robot) ->
    listener = @
    @robot.brain.on 'save', (data) ->
      listener.robot.logger.debug("Syncing data on 'save': #{JSON.stringify(data)}")
      listener.sync(data)
      # When the exit event is triggered, the listener attempts to use the
      # synchronousSync method to prevent the event loop from exiting during save.
      process.on 'exit', ->
        #listener.synchronousSync(data)
        return listener.deasyncSync(data)
      # TODO determine if the following are needed.
      process.on 'SIGINT', ->
        return listener.deasyncSync(data)
      process.on 'SIGTERM', ->
        return listener.deasyncSync(data)
    @robot.brain.on 'loaded', (data) ->
      listener.robot.logger.debug("Syncing data on 'loaded': #{JSON.stringify(data)}")
      listener.sync(data)
    @loadJSON()
  
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

  # The deasyncSync method blocks the event loop.  Not recomended for autosave
  # intervals because the user experiance will degrade.  Use when the event loop must
  # be blocked to prevent data loss.  For example, when process.exit is used.
  deasyncSync: (data) ->
    listener = @
    lastrev = deasyncPromise(@client.get(@brainKey).string())
    try
      lastrev = JSON.parse(lastrev)
    catch e
      listener.robot.logger.error("Error parsing data: #{e}")
    if !_.isEqual(lastrev, data)
      try
        data = JSON.stringify(data)
      catch e
        listener.robot.logger.error("Error stringifying data: #{e}")
      try
        deasyncPromise(listener.client.put(listener.brainKey).value(data))
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
