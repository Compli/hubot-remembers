Helper = require('hubot-test-helper')
chai = require 'chai'
sinon = require 'sinon'
require('sinon-as-promised')
{ Etcd3 } = require 'etcd3'
expect = chai.expect
helper = new Helper('../src')
BrainListener = require '../src/lib/listener.coffee'

#The EtcdMock class mimics the behavior of the etcd3 client library
describe 'BrainListener', ->
  robot = helper
  client = new Etcd3()
  brainKey = "/test-brain/#{Math.random()}"
  
  beforeEach ->
    mock = client.mock({ exec: sinon.stub() })
    mock.exec.resolves({ kvs: [{ key: 'foo', value: 'bar' }]})
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
    listener = new BrainListener(brainKey, client, @room.robot)
    expect(listener.client.mock).to.exist
    expect(listener.client.mock).to.eql(client.mock)

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
