# Protocol notes

These notes describe observable local interfaces. They are not a specification.

## Base URL

~~~text
http://127.0.0.1:3080
~~~

## Health

~~~http
GET /chatterfly/v1/health
~~~

Observed fields include:

~~~text
ok
plugin
version
protocol
dsh
workspace
subscribers
running
queued
sessions
user_sessions
session_failure
capabilities
~~~

Capabilities observed in the tested build:

~~~text
approval
questions
deliverables
resume
~~~

## Submit task

~~~http
POST /chatterfly/v1/tasks
Content-Type: application/json
~~~

Observed body shape:

~~~json
{
  "new_session": false,
  "text": "<transcribed task>",
  "token": "<opaque>",
  "user_id": "1"
}
~~~

A successful response includes a task_id.

## Event stream

~~~http
GET /chatterfly/v1/events
Accept: text/event-stream
~~~

The client contains lifecycle handling for queueing, task start, completion/error, session state, and stream-gap recovery.

## Other routes

~~~text
POST /chatterfly/v1/answers
POST /chatterfly/v1/cancel
GET  /chatterfly/v1/tasks
~~~

## Session navigation

~~~text
http://127.0.0.1:3080/?chatterflySession=<session-id>
~~~

## Authentication note

The task body contains a token.

This repository intentionally treats it as opaque and does not document token generation, signature internals, secret extraction, replay, or bypass techniques.

For protocol research, redact it at capture time.
