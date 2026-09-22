# Architecture

## Verified path

~~~mermaid
flowchart TD
    A[Voice / experimental DSH mode] --> B[Chatterfly voiceinput.exe]
    B --> C[POST 127.0.0.1:3080/chatterfly/v1/tasks]
    C --> D[dsh-ime plugin]
    D --> E[DeepSeek Harness]
    E --> F[deepseek-official provider]
    F --> G[DeepSeek model]
    E --> H[Agent tools]
    H --> I[Files / Shell / Workspace]
    D --> J[SSE /chatterfly/v1/events]
    J --> B
    E --> K[DSH Web GUI]
~~~

## What is observed vs inferred

### Directly observed

- voiceinput.exe connects to 127.0.0.1:3080.
- It submits POST /chatterfly/v1/tasks.
- The body includes text, user_id, new_session, and an opaque token.
- Tencent ships dsh-ime.tgz and dsh-chatterfly-web.tgz.
- Tencent ships install-dsh-ime.mjs.
- After installing the shipped plugins into DSH, /chatterfly/v1/health reports ok: true.
- Voice tasks create DSH sessions and can execute Agent tools.
- A voice task successfully created a Python file in the configured workspace.

### Identified from local client/plugin behavior

- /chatterfly/v1/events is used for the event stream.
- /answers and /cancel support interactive task lifecycle.
- Session URLs use the chatterflySession query parameter.
- The integration models queueing/running/terminal states and interactive approvals/questions.

## Why 3080 matters

DeepSeek Harness itself uses port 3080 by default. Chatterfly's local client is therefore built around the conventional local DSH Web endpoint rather than a Tencent-only cloud endpoint.

The important architectural point is that Chatterfly is functioning as an **input/interaction surface for a local Agent Harness**.
