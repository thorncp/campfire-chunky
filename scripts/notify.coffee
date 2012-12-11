# Description:
#   Notifies you by Prowl when you're mentioned
#
# Dependencies:
#   "prowler": "0.0.3"
#
# Configuration:
#   None
#
# Commands:
#   hubot notify me as TRIGGER with YOUR_PROWL_API_KEY
#   hubot list notifiers
#
# Author:
#   marten

Prowl = require "prowler"
QS = require "querystring"

module.exports = (robot) ->
  robot.hear /\w+/, (msg) ->
    text = msg.message.text
    registeredUsers = robot.brain.data.notifiers

    notifications = []

    notifyUser = (username) ->
      username = username.toLowerCase()
      notifications.push(username) unless username in notifications

    shouldNotifyUser = (username) ->
      username.toLowerCase() of registeredUsers

    notifyAll = ->
      for username of registeredUsers
        notifyUser(username)

    shouldNotifyAll = ->
      [/@all/, /@everyone/, /@everybody/].some (pattern) ->
        pattern.test(text)

    sendNotification = (username) ->
      [protocol, apikey] = registeredUsers[username].split(":")
      # msg.send("Notified #{username} by #{protocol}:#{apikey}")
      if protocol of notifiers
        notifiers[protocol](apikey)

    notifiers =
      prowl: (apikey) ->
        notification = new Prowl.connection(apikey)
        notification.send
          application: "Campfire"
          event: "Mention"
          description: text

    if shouldNotifyAll()
      notifyAll()
    else
      for word in text.split(/\b/) # TODO optimize
        if shouldNotifyUser(word)
          notifyUser(word)

    for username in notifications
      sendNotification(username)

  robot.respond /notify me as (\w+) with (\w+)/i, (msg) ->
    username = msg.match[1].toLowerCase()
    apikey   = msg.match[2].toLowerCase()
    robot.brain.data.notifiers ?= {}
    robot.brain.data.notifiers[username] = "prowl:#{apikey}"
    msg.send "OK, #{username}"

  robot.respond /list notifiers/i, (msg) ->
    for username, apikey of robot.brain.data.notifiers
      msg.send("I notify #{username} with #{apikey}")
