# connects a gitter and an irc room
# runs in the background, almost no interaction with the adapter
# (ie you can't control him by saying "cloudsbot chat-forward irc irc.freenode.net #brooklyncentral gitter brooklyncentral/brooklyn --bidi")
# though you can say anything about chat...forward... and it will give status

# requires HUBOT_GITTER2_TOKEN exported before running, with token from developers.gitter.im

GitterAdapter = require 'hubot-gitter2'
Irc = require('irc')

module.exports = (robot) ->

  # ---- CONFIGURE THIS ----

  me = "brooklyn-bot"

  gitter_room_uri = 'brooklyncentral/brooklyn'

  irc_host = 'irc.freenode.net'
  irc_channel = '#brooklyncentral'

  # ---- FORWARDING in BG ----

  start_date = new Date()
  count_to_gitter = 0
  count_to_irc = 0

  irc_client = null;
  gitter_target_room_client = null;

  gitter = GitterAdapter.use(robot).gitterClient()
  gitter.on 'ready', =>
    gitter.sessionUser().asyncRooms (error, rooms) =>
      gitter.asyncRoom { uri: gitter_room_uri }, (error, room) -> 
        room.isListening yes
        room.on 'chatMessages.chatMessages', (msg) ->
          if (!msg.model || !msg.model.fromUser) 
            return;
          if (msg.model.fromUser.username != me)
            count_to_irc++
            irc_client.say irc_channel, "#{msg.model.fromUser.username} (on Gitter): #{msg.model.text}"
        gitter_target_room_client = room
        console.log "CHAT-FORWARD joined gitter room #{ gitter_room_uri }"
  gitter.on 'error', (args...) ->
    console.log "Error"
    console.log args
    console.trace()

  irc_client = new Irc.Client irc_host, me, { userName: me, channels: [ irc_channel ] }
  irc_client.on 'error', (args...) ->
    console.log "Error"
    console.log args
    console.trace()
  irc_client.on 'connect', ->
    irc_client.join irc_channel, (args...) ->
      irc_client.addListener 'message', (from, to, message) ->
        if (gitter_target_room_client && from != me)
          count_to_gitter++
          gitter_target_room_client.asyncSend "#{ from } (on IRC): #{ message }"
    console.log "CHAT-FORWARD joined irc #{irc_host} #{irc_channel}"

  # ---- GIVING STATUS ----

  robot.respond /.*chat.*forward.*/i, (res) ->
     res.reply "Yes, I'm here forwarding between IRC #{ irc_channel } and Gitter #{ gitter_room_uri } since #{ start_date }. \n" +
       "I'm not configurable but I can tell you message counts: #{count_to_gitter} #{count_to_irc}."


