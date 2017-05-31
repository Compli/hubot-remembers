Helper = require('hubot-test-helper')
chai = require 'chai'

expect = chai.expect

helper = new Helper('../src')
BrainListener = require '../src/lib/listener.coffee'

#The EtcdMock class mimics the behavior of the etcd3 client library
class EtcdMock
  constructor: ->
    @data = {}
  
  get: (key) ->
    p = new Promise (resolve, reject) ->
      value = @data[key]
      if value
        resolve value
      else
        reject new Error("Missing key #{key}")

describe 'BrainListener', ->
  robot = helper
  client = new EtcdMock
  brainKey = "/test-brain/#{Math.random()}"
  
  beforeEach ->
    @room = helper.createRoom()
    client.data = {}
    client.data[brainKey] = {
      value: JSON.stringify({users: {}, _private: {}})
    }
    @room.robot.brain.data =
      users: {}
      _private: {}

  afterEach ->
    @room.destroy()

  it 'uses injected etcd client', ->
    console.log robot
    listener = new BrainListener(brainKey, client, @room.robot)
    expect(listener.client).to.exist
    # listener.client.expect.to.eql(client)

describe 'remembers', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  it 'responds to hello', ->
    @room.user.say('alice', '@hubot hello').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot hello']
        ['hubot', '@alice hello!']
      ]

  it 'hears orly', ->
    @room.user.say('bob', 'just wanted to say orly').then =>
      expect(@room.messages).to.eql [
        ['bob', 'just wanted to say orly']
        ['hubot', 'yarly']
      ]
