# cloudsbot

cloudsbot is a chat bot built on the [Hubot][hubot] framework.

[hubot]: http://hubot.github.com

He will:
* chat-forward messages between IRC and Gitter

He could:
* collect other info (failed builds, etc) and add them to IRC and Gitter
* do common tasks for people if we have IRC meetings


### Build

Normally it's `npm install`.  An IRC / ICU library libconv can cause errors.
For me it worked with them but some investigation would be useful.


### Running Locally

You can test your hubot by running the following, however some plugins will not
behave as expected unless the [environment variables](#configuration) they rely
upon have been set.

You can start cloudsbot locally by running:

    % HUBOT_GITTER2_TOKEN=... bin/hubot

You'll see some start up output and a prompt:

    cloudsbot>

Then you can interact with cloudsbot by typing `cloudsbot help`.

    cloudsbot> cloudsbot help
    ...

The chat forwarding runs in the background.


### Running Prod

In prod you will want the process nohupped, maybe respawned. 

On Ubuntu you may have to change the Ham radio `node` link to point at `nodejs`.


### Limitations

Currently `-a gitter2` to have it listen in the gitter room doesn't seem to work.
No errors, but the gitter client the forwarder uses no longer reads nor writes;
I guess hubot-gitter2 is a singleton.


### Configuration

See custom scripts in scripts/

