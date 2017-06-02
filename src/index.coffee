'use strict'
util = require 'util'
{ Etcd3 } = require 'etcd3'
client = new Etcd3
BrainListener = require './lib/listener'

# This module initializes the etcd client and attaches it to a listener
# that listens for events from the robot object.
module.exports = (robot) ->
  robot.setAutoSave = true
  robot.brain.resetSaveInterval(5)
  brainKey = process.env.HUBOT_ETCD_BRAIN_KEY or 'hubot-brain/brain-dump'
  client = new Etcd3()
  listener = new BrainListener(brainKey, client, robot)
  #listener # Instantiate the listener
  robot.hear /save/, (res) ->
    robot.brain.emit 'save'
