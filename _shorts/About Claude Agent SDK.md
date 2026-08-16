
## Simulating Claude Agent SDK with Shell

The Claude Agent SDK bundles a Claude Code inside it, with a thin wrapper on top. It first launches the `claude` CLI process, redirects the standard input and output of that process, and then interacts with the process via a JSON stream. The interaction unit of this "stream" is a JSON object — you can write JSON objects in one by one, and the `claude` CLI process will output JSON objects one by one.

You can simulate this process with shell commands.


### Step 1: Create a FIFO file

```shell
mkfifo /tmp/claude.in
```

This command creates a special FIFO file `/tmp/claude.in`, which will be used as the input channel for the `claude` CLI.

### Step 2: Start claude and redirect

```shell
claude --output-format stream-json --verbose --system-prompt "" --tools Read,Edit,Glob --permission-mode acceptEdits --input-format stream-json < /tmp/claude.in > /tmp/claude.out 2> /tmp/claude.err
```

This command starts the `claude` CLI process:
- Configures both input and output to `stream-json` mode;
- Uses `/tmp/claude.in` as the input channel;
- Uses `/tmp/claude.out` as the output channel;
- Uses `/tmp/claude.err` as the standard error output channel.

### Step 3: Listen to and view the output channel

Note: **Open a new terminal tab** and enter the following command to continuously listen to the output channel of the `claude` CLI:

```shell
tail -f /tmp/claude.out
```

### Step 4: Send the initialization message

Note: **Open another new terminal tab** (the 3rd terminal tab) and enter the following command:

```shell
echo '{"type": "control_request", "request_id": "req_1_123", "request": {"subtype": "initialize", "hooks": null}}\n' > /tmp/claude.in
```

This command sends an `initialize` message in JSON format to the `claude` CLI, telling Claude Code to initialize.

In the output channel from earlier (the terminal tab running `tail`), you will see output similar to the following:

![[Pasted image 20260523110341.png]]

### Step 5: Send a user message/instruction

In the 3rd terminal tab you opened, enter the following command:

```shell
echo '{"type": "user", "session_id": "", "message": {"role": "user", "content": "Summarize what the current codebase mainly does"}, "parent_tool_use_id": null}\n' > /tmp/claude.in
```

In the output channel above, you will see a series of messages, mainly tool calls and tool call results. Something like the following:

![[Pasted image 20260523110427.png]]
![[Pasted image 20260523110746.png]]

