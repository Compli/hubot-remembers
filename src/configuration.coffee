'use strict'
util = require 'util'
{ Etcd3 } = require 'etcd3'
client = new Etcd3
BrainListener = require './listener'

hubot = require 'hubot'
console.log(hubot.emit)

# TODO remove this example
client = new Etcd3()
client.put('foo').value('bar')
  .then () ->
    client.get('foo').string()
  .then (value) ->
    console.log("value was ", value)
# End example

module.exports = (robot) ->
  robot = robot or hubot
  brainKey = process.env.HUBOT_ETCD_BRAIN_KEY or 'hubot-brain/brain-dump'
  # TODO determineif host & port are neccisary.  These are set by the etcd3 constructor.
  etcdHost = process.env.HUBOT_ETCD_HOST or 'localhost'
  etcdPort = parseInt(process.env.HUBOT_ETCD_PORT) or 2379
  client = new Etcd3()
  listener = new BrainListener(brainKey, client, robot)
  listener
