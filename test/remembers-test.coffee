Helper = require('hubot-test-helper')
chai = require 'chai'
require('chai-as-promised')
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
    options = {}
    options.overrideAutosave = true
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
    options = {}
    options.overrideAutosave = true
    listener = new BrainListener(brainKey, client, @room.robot, options)
    expect(listener.client.mock).to.exist
    expect(listener.client.mock).to.eql(client.mock)

  it 'syncs to etcd on loaded', (done) ->
    options = {}
    options.overrideAutosave = true
    listener = new BrainListener(brainKey, client, @room.robot, options)
    @room.robot.on 'loaded', (data) ->
      expect(listener.client.data[brainKey]).to.exist
      expect(listener.client.data[brainKey].value).to.eql(JSON.stringify(listener.robot.brain.data))
      done()
    @room.robot.emit 'loaded'

  it 'syncs to etcd on save', (done) ->
    options = {}
    options.overrideAutosave = true
    listener = new BrainListener(brainKey, client, @room.robot, options)
    @room.robot.on 'save', (data) ->
      expect(client.data[brainKey]).to.exist
      done()
    @room.robot.emit 'save'
  
  it 'turns autosave off', (done) ->
    options = {}
    options.overrideAutosave = true
    listener = new BrainListener(brainKey, client, @room.robot, options)
    @room.robot.on 'loaded', (data) ->
      expect(listener.robot.brain.autoSave).to.equal(false)
      done()
    @room.robot.emit 'loaded'
  
  it 'turns autosave on', (done) ->
    options = {}
    options.overrideAutosave = false
    listener = new BrainListener(brainKey, client, @room.robot, options)
    @room.robot.on 'loaded', (data) ->
      expect(listener.robot.brain.autoSave).to.equal(true)
      done()
    @room.robot.emit 'loaded'
