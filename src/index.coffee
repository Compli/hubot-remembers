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
options = {}
options.overrideAutosave = if typeof process.env.HUBOT_AUTOSAVE_OVERRIDE == 'undefined' then false else process.env.HUBOT_AUTOSAVE_OVERRIDE
brainKey = if typeof process.env.HUBOT_ETCD_BRAIN_KEY == 'undefined' then 'hubot-brain/brain-dump' else process.env.HUBOT_ETCD_BRAIN_KEY
saveInterval = if typeof process.env.HUBOT_ETCD_SAVE_INTERVAL == 'undefined' then 90 else process.env.HUBOT_ETCD_SAVE_INTERVAL
brainHosts = if typeof process.env.HUBOT_ETCD_BRAIN_HOST == 'undefined' then '127.0.0.1:2379' else process.env.HUBOT_ETCD_BRAIN_HOST
# This module initializes the etcd client and attaches it to a listener
# that listens for events from the robot object.
module.exports = (robot) ->
  client = new Etcd3({hosts: [brainHosts]})
  listener = new BrainListener(brainKey, client, robot, options)
  robot.brain.resetSaveInterval(saveInterval)
