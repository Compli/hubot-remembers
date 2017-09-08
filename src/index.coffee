# Description:
#   A brain store for Hubot's brain using the etcd v3 API.
#
# Dependencies:
#   See package.json
#
# Configuration:
#   HUBOT_ETCD_BRAIN_KEY
#     Default is 'hubot-brain/brain-dump'
#     Use this value to store the key used for Hubot's brain data.
#   HUBOT_ETCD_SAVE_INTERVAL
#     Default is 90 secods
#     Use this to specify how often autosave should be attempted
#
# Notes:
#   Etcd should be configured to listen at localhost:2379
#
# Author:
#   Joe Creager 

'use strict'
util = require 'util'
{ Etcd3 } = require 'etcd3'
BrainListener = require './lib/listener'
brainKey = process.env.HUBOT_ETCD_BRAIN_KEY or 'hubot-brain/brain-dump'
autosave = process.env.HUBOT_AUTOSAVE_BOOL or false
saveInterval = process.env.HUBOT_ETCD_SAVE_INTERVAL or 90
brainHosts = process.env.HUBOT_ETCD_BRAIN_HOST or '127.0.0.1:2379'

# This module initializes the etcd client and attaches it to a listener
# that listens for events from the robot object.
module.exports = (robot) ->
  if autosave = true
    robot.brain.resetSaveInterval(saveInterval)
  client = new Etcd3({hosts: [brainHosts]})
  listener = new BrainListener(brainKey, client, robot)
