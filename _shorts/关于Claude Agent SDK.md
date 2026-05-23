
## 用Shell模拟一下Claude Agent SDK

Claude Agent SDK内部打包了一个Claude Code，在上面做了一层浅的封装。它先启动claude CLI进程，重定向了这个进程的标准输入输出，然后通过json流的方式与这个进程交互。这个「流」的交互单元是一个json，你可以一个json一个json的写入，然后claude CLI进程会一个json一个json的输出。

可以用shell命令模拟这个过程。


### 步骤1：创建一个fifo文件

```shell
mkfifo /tmp/claude.in
```

这个命令创建了一个特殊的fifo文件`/tmp/claude.in`，它会用作claude CLI的输入通道。

### 步骤2：启动claude并重定向

```shell
claude --output-format stream-json --verbose --system-prompt "" --tools Read,Edit,Glob --permission-mode acceptEdits --input-format stream-json < /tmp/claude.in > /tmp/claude.out 2> /tmp/claude.err
```

这个命令启动claude CLI进程：
- 把输入和输出配置成`stream-json`模式；
- `/tmp/claude.in`作为输入通道；
- `/tmp/claude.out`作为输出通道；
- `/tmp/claude.err`作为标准错误输出通道。

### 步骤3：监听并查看输出通道

注意：**打开一个新的终端Tab**，输入如下命令，持续监听claude CLI的输出通道：

```shell
tail -f /tmp/claude.out
```

### 步骤4：输入初始化消息

注意：再**打开一个新的终端Tab**（第3个终端Tab），输入如下命令：

```shell
echo '{"type": "control_request", "request_id": "req_1_123", "request": {"subtype": "initialize", "hooks": null}}\n' > /tmp/claude.in
```

这个命令以json格式发送一条`initialize`类型的消息给claude CLI，让Claude Code做初始化。

在前面的输出通道（敲tail的那个终端Tab）上会输出类似下面的消息：

![[Pasted image 20260523095524.png]]

### 步骤5：输入user消息/指令

在打开的第3个终端Tab，输入如下命令：

```shell
echo '{"type": "user", "session_id": "", "message": {"role": "user", "content": "总结一下当前代码库主要做了什么"}, "parent_tool_use_id": null}\n' > /tmp/claude.in
```

在前面的输出通道上会输出一系列消息，主要是调用工具和工具调用结果。类似下面这样：

![[Pasted image 20260523100449.png]]
![[Pasted image 20260523100551.png]]



