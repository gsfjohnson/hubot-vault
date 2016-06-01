# Description:
#   Manage vault with Hubot.
#
# Dependencies:
#   "sys": ">= 0.0.0"
#
# Configuration:
#   None
#
# Commands:
#   hubot vault help - list commands
#
# Author:
#   gsfjohnson

fs = require('fs')
sys = require('sys')
exec = require('child_process').exec;

vault_token = ''
modname = rolename = 'vault'

sendqueue = []
servicequeue = ->
  o = sendqueue.shift()
  msg = o['msg']
  out = o['out']
  msg.send {room: msg.message.user.name}, out

isAuthorized = (robot, msg) ->
  if robot.auth.isAdmin(msg.envelope.user) or robot.auth.hasRole(msg.envelope.user,modrole)
    return true
  msg.send {room: msg.message.user.name}, "Not authorized.  Missing `#{modrole}` role."
  return false

fileExistsSendAndReturnTrue = (msg, file, failresponse) ->
  if fs.existsSync file
    msg.send {room: msg.message.user.name}, failresponse
    return true
  return false  # does not exist

fileMissingSendAndReturnTrue = (msg, file, failresponse) ->
  if ! fs.existsSync file
    msg.send {room: msg.message.user.name}, failresponse
    return true
  return false  # file exists

execAndSendOutput = (msg, cmd) ->
  exec cmd, (error, stdout, stderr) ->
    if stderr
      msg.send {room: msg.message.user.name}, "stderr:\n```\n#{stderr}\n```"
    else if error
      msg.send {room: msg.message.user.name}, "Error: #{error}"
    if stdout
      msg.send {room: msg.message.user.name}, "```\n#{stdout}\n```"

module.exports = (robot) ->

  robot.respond /vault help$/, (msg) ->
    cmds = []
    arr = [
      "#{modname} token-lookup - get info about current token"
      "#{modname} read <path> - read a secret"
      "#{modname} set-token <token> - set the token"
    ]

    for str in arr
      cmd = str.split " - "
      cmds.push "`#{cmd[0]}` - #{cmd[1]}"

    if msg.message?.user?.name?
      robot.send {room: msg.message?.user?.name}, cmds.join "\n"
    else
      msg.reply cmds.join "\n"

  robot.respond /vault set-token ([^\s]+)$/i, (msg) ->
    return unless isAuthorized robot, msg

    vault_token = msg.match[1]
    return msg.send {room: msg.message.user.name}, "```\n#{vault_token}\n```"

  robot.respond /vault (read) ([^\s]+)$/i, (msg) ->
    return unless isAuthorized robot, msg

    action = msg.match[1]
    path = msg.match[2]

    ekvs = []
    ekvs.push "#{k}=#{v}" for k,v of { 'VAULT_TOKEN': vault_token }
    environment = ekvs.join " "

    cmd = "#{environment} vault #{action} #{path}"
    execAndSendOutput msg, cmd

  robot.respond /vault (token-lookup)$/i, (msg) ->
    return unless isAuthorized robot, msg

    action = msg.match[1]

    ekvs = []
    ekvs.push "#{k}=#{v}" for k,v of { 'VAULT_TOKEN': vault_token }
    environment = ekvs.join " "

    cmd = "#{environment} vault #{action}"
    execAndSendOutput msg, cmd
