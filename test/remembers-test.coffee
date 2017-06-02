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
    client.unmock()

  it 'uses injected etcd client', ->
    listener = new BrainListener(brainKey, client, @room.robot)
    expect(listener.client.mock).to.exist
    expect(listener.client.mock).to.eql(client.mock)

  # TODO what does this even test?
  it 'syncs to etcd on @robot.set', (done) ->
    listener = new BrainListener(brainKey, client, @room.robot)
    doneOnce = false
    listener.on 'synced', (data) ->
      if doneOnce
        return
      expect(client.data[brainKey]).to.exist
      expect(JSON.parse(client.data[brainKey].value)).to.eql('boop')
      doneOnce = true
    done()
    @room.robot.brain.set('beep', 'boop')

  it 'syncs to etcd on @robot.save', (done) ->
    listener = new BrainListener(brainKey, client, @room.robot)
    listener.on 'saved', (data) ->
      expect(client.data[brainKey]).to.exist
    done()
    @room.robot.brain.save()

  it 'merges the etcd data to robot.brain via loadJSON', (done) ->
    boop = "#{Math.random()}"
    client.data[brainKey] = {
      value: JSON.stringify({users: {}, _private: {beep: boop}})
    }
    listener = new BrainListener(brainKey, client, @room.robot)
    listener.on 'loaded', ->
      console.log listener.robot.brain.data._private
      expect(listener.robot.brain.data._private.beep).to.eql(boop)
      done()
    listener.loadJSON()

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
