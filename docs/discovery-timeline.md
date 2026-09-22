# Discovery timeline — 2026-09-22

This document keeps the research trail without publishing secrets or proprietary binaries.

## 1. Experimental voice mode

A local probe showed three voice modes. Mode 2 behaved differently from ordinary dictation and command mode.

## 2. Network/process probe

After triggering Mode 2, voiceinput.exe repeatedly attempted to connect to:

~~~text
127.0.0.1:3080
~~~

At this point there was no listener, which corresponded with the client-side “DeepSeek Harness connection timeout” notification.

## 3. Minimal local catcher

A temporary local HTTP catcher on port 3080 captured the request shape:

~~~text
POST /chatterfly/v1/tasks
~~~

The request carried task text, new_session, user_id, and an opaque token.

The catcher deliberately redacted the token and did not attempt to validate, forge, reuse, or reverse its authentication mechanism.

## 4. Stock DSH test

Stock DeepSeek Harness was launched on port 3080.

It was alive, but stock DSH did not expose /chatterfly/v1/tasks, proving that an additional adapter/plugin was required.

## 5. Local binary/package inspection

The installed Chatterfly files revealed:

~~~text
/chatterfly/v1/tasks
/chatterfly/v1/answers
/chatterfly/v1/health
/chatterfly/v1/cancel
/chatterfly/v1/events
~~~

More importantly, the Chatterfly installation itself contained:

~~~text
dsh-ime/plugins/dsh-ime.tgz
dsh-ime/plugins/dsh-chatterfly-web.tgz
dsh-ime/scripts/install-dsh-ime.mjs
~~~

This changed the direction of the work: instead of reimplementing the protocol, use Tencent's own shipped DSH integration.

## 6. Official plugin installation

The shipped installer was executed against a local DeepSeek Harness profile.

Health then returned:

~~~json
{
  "ok": true,
  "plugin": "chatterfly",
  "version": "1.0.8",
  "protocol": 1
}
~~~

## 7. Model credential and cost control

A DeepSeek API key was configured locally in DSH's credential store.

The model default was intentionally set to a lower-cost route:

~~~text
deepseek-official / deepseek-flash
reasoningEffort: low
~~~

## 8. End-to-end task

Voice command:

~~~text
帮我用 Python 写一个从 1 数到 10 的小代码
~~~

The Chatterfly task appeared in the DSH Web GUI, the model ran, tools executed, and a Python file was created in the workspace.

At that point the integration was end-to-end verified.
