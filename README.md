# hubot-remembers

![Remember when...?  Hubot remembers](hubot-remembers.png)

A hubot script that backs up hubot's brian to etcd using the etcd v3 gRPC API.

See [`src/index.coffee`](src/index.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-remembers --save`

Then add **hubot-remembers** to your `external-scripts.json`:

```json
[
  "hubot-remembers"
]
```

Make sure that etcd is running at `localhost:2379`.

## Configuration

By default, this module autosaves every 90 seconds, and uses the object key `hubot-brain/brain-dump`.  To configure these settings, add the following to hubot's `.env` file.

```
export HUBOT_ETCD_BRAIN_KEY="<my-brain-dump>"
export HUBOT_ETCD_SAVE_INTERVAL=<my-save-interval-integer-in-seconds>
```

Although hubot-remembers autosaves at the sepcified interval.  A new database revision is only done when hubot's brain data object has changed.

## NPM Module

https://www.npmjs.com/package/hubot-remembers

## Tests

`npm test`

## Development

To develop locally, clone this repository.  Then set up a link between this repository and your hubot instance:

```
cd <directory/containing/hubot-remembers>
npm link
cd <directory/containing/hubot-instance>
npm link hubot-remembers
npm install
```

This module offers a generous, but optional amount of debugging output.  To enable debugging output add the following to hubot's `.env` file or execute it on the command line to enable debugging in the current terminal session.

```
export HUBOT_LOG_LEVEL="debug"
```

## TODO

- Add support for additional hosts/ports
