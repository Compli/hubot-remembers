'use strict'
util = require 'util'
{ Etcd3 } = require 'etcd3'
client = new Etcd3
BrainListener = require './lib/listener'

# This module initializes the etcd client and attaches it to a listener
# that listens for events from the robot object.
module.exports = (robot) ->
  saveInterval = process.env.HUBOT_ETCD_SAVE_INTERVAL or 60 * 15 * 1000 # 15 minutes
  brainKey = process.env.HUBOT_ETCD_BRAIN_KEY or 'hubot-brain/brain-dump'
  client = new Etcd3()
  listener = new BrainListener(brainKey, client, robot)
  #listener # Instantiate the listener
  do poll = ->
    robot.brain.emit 'save'
    setTimeout poll, 60000
  robot.hear /save/, (res) ->
    robot.brain.emit 'save'
