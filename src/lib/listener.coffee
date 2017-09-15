'use strict'
_ = require 'lodash'

class BrainListener
  # The BrainListener constructor listens for the 'saved' and events and 
  # attempts to call the @loadJSON method.  If the save event is called by
  # the process.exit event, the constructor attempts to synchronously save
  # the data to etcd.
  constructor: (@brainKey, @client, @robot, @options) ->
    listener = @
    # process.exit does not wait for asynchronous functions to complete before exiting
    # this may not matter as the data in the brain is saved every time the brain changes
    process.on 'exit', ->
      listener.robot.logger.warning("Data failed to save: process.exit called before asynchronous functions completed.")
    @robot.brain.on 'save', (data) ->
        listener.robot.logger.debug("Syncing data on 'save': #{JSON.stringify(data)}")
        listener.sync(data)
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

  # The loadJSON method calls the client.get method and calls data matching the
  # brainKey.  When the data is loaded, the 'loaded' event is emitted.
  loadJSON: ->
    listener = @
    if listener.options.overrideAutosave == false then listener.robot.brain.setAutoSave true else listener.robot.brain.setAutoSave false
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

module.exports = BrainListener
