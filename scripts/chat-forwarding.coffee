# connects a gitter and an irc room
# runs in the background, almost no interaction with the adapter
# (ie you can't control him by saying "cloudsbot chat-forward irc irc.freenode.net #brooklyncentral gitter brooklyncentral/brooklyn --bidi")
# though you can say anything about chat...forward... and it will give status

# requires HUBOT_GITTER2_TOKEN exported before running, with token from developers.gitter.im

GitterAdapter = require 'hubot-gitter2'
Irc = require('irc')
Fs = require 'fs'

module.exports = (robot) ->

  config = {}
  try
    config = Fs.readFileSync "config.json"
    config = JSON.parse config
    console.log "Successfully read configuration from config.json"
  catch error
    console.log "Unable to read configuration from config.json, will attempt to pull config from envvars"

  # ---- CONFIGURATION : config.json > envvar ----
  me = config.bot_name or process.env.HUBOT_BOT_NAME
  gitter_room_uri = config.gitter_room_uri or process.env.HUBOT_GITTER_ROOM
  irc_channel = config.irc_channel or process.env.HUBOT_IRC_CHANNEL
  muted_users = config.muted_users or process.env.HUBOT_MUTED_USERS.split(',') or 'ASFBot'
  irc_host = config.irc_host or process.env.HUBOT_IRC_HOST or 'irc.freenode.net'

  unless me?
    console.log "Missing HUBOT_BOT_NAME in environment: please set and try again"
    process.exit(1)
  unless gitter_room_uri?
    console.log "Missing HUBOT_GITTER_ROOM in environment: please set and try again"
    process.exit(1)
  unless irc_channel?
    console.log "Missing HUBOT_IRC_CHANNEL in environment: please set and try again"
    process.exit(1)
    
  # Trim all whitespace from muted users if present
  for user, index in muted_users
    muted_users[index] = user.replace /^\s+|\s+$/g, ""

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
          if (!msg.model isnt !msg.model.fromUser) 
            return;
          if (msg.model.fromUser.username isnt me and msg.model.fromUser.username not in muted_users)
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
        if (gitter_target_room_client and from isnt me and from not in muted_users )
          count_to_gitter++
          gitter_target_room_client.asyncSend "#{ from } (on IRC): #{ message }"
    console.log "CHAT-FORWARD joined irc #{irc_host} #{irc_channel}"

  # ---- GIVING STATUS ----

  robot.respond /.*chat.*forward.*/i, (res) ->
     res.reply "Yes, I'm here forwarding between IRC #{ irc_channel } and Gitter #{ gitter_room_uri } since #{ start_date }. \n" +
       "I'm not configurable but I can tell you message counts: #{count_to_gitter} #{count_to_irc}."


