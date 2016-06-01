chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'vault', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/vault')(@robot)

  it 'registers a respond listener for vaulting', ->
    expect(@robot.respond).to.have.been.calledOnce
