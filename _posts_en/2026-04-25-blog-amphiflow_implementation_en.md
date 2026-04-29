---
layout: post
category: ml
title: Why Can Agent and Workflow Be Unified in a Single Architecture?
date: 2026-04-25 00:00:00 +0800
published: true
---

This year, we're seeing a noticeable shift at the AI application layer—from workflow-based automation toward more autonomous agents. Tools like n8n and Dify represent the former, while OpenClaw, Hermes, and CoWork are early examples of the latter. That said, new paradigms rarely replace old ones outright. More often, they evolve by absorbing and reshaping what came before—a kind of “sublation” rather than simple replacement.

In my previous article on our new technology stack [AmphiLoop](https://medium.com/towards-artificial-intelligence/beyond-autonomous-why-im-building-an-amphibious-agent-fcae9a409220), I introduced a new programmatic architecture called "Amphiflow". **Amphiflow is what I believe to be the first truly "decision–execution decoupled" agent architecture. It combines workflow and agent paradigms into a single runtime, with the ability to switch between them automatically**.

[<img src="/cover-image/amphiflow-implementation/cover.png" width="80%" />](/cover-image/amphiflow-implementation/cover.png)

Today, let's analyze the implementation principles behind this architecture and examine how it can leverage the advantages of both modes simultaneously.

<!--more-->

> [Click here to download the source code ➜ https://github.com/bitsky-tech/AmphiLoop/](https://github.com/bitsky-tech/AmphiLoop/)

### How Amphiflow Works

To accomplish any task, two factors must be determined: **the goal and the path**. Let's use a simple example:

[<img src="/assets/images_amphiflow_tech/grid_s_d.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d.png)

In the grid above, suppose there is a robot at point S, and its task is to move from point S to point D. Let's also assume this robot can only move horizontally or vertically.

Following the workflow mode (which is also the traditional software approach), generally speaking, we need to specify a concrete path during programming for the robot to know how to act. As shown below:

[<img src="/assets/images_amphiflow_tech/grid_s_d_path.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_path.png)

Of course, there is more than one path from S to D. But our workflow only needs to indicate one path.

In contrast, following the autonomous agent mode, there is no need to specify a path in advance. We only need to specify the task goal (i.e., reaching point D), and the LLM will automatically find the path. This is also **the essential difference between today's AI Agent technology and traditional software**. For a more detailed discussion, see the section "*Programming Paradigm Shift: From Step-Oriented to Goal-Oriented*" in "The Software Development Paradigm in the AI Agent Era".

Now suppose that during the robot's movement along the predetermined path, it encounters an unexpected "obstacle" (the red barrier in the figure below).

[<img src="/assets/images_amphiflow_tech/grid_s_d_failed.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_failed.png)

If the robot is driven by workflow mode, and this red obstacle is something that could not be anticipated during workflow programming, then there is only one outcome at this point: task failure.

However, if the robot switches to agent mode when encountering the obstacle, it might go around it and continue moving forward. As shown below:

[<img src="/assets/images_amphiflow_tech/grid_s_d_detour.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_detour.png)

If the obstacle turns out to be far beyond expectations—so much so that the original path becomes completely unusable—the agent mode may simply replan a new path, as illustrated below:

[<img src="/assets/images_amphiflow_tech/grid_s_d_replan.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_replan.png)

Although the above example is merely an analogy, it already illustrates **the most fundamental principle of Amphiflow**:
- Amphiflow initially operates in workflow mode. Once it encounters an unexpected obstacle and an error occurs at a certain step, it switches to agent mode. In agent mode, two levels of degradation may occur.
- First, it attempts a minor degradation. It tries to "fix" the error in the current step. If it can correctly complete the current step in agent mode, it switches back to workflow mode and continues running (corresponding to the situation where it encounters an obstacle and goes around it). Otherwise, after multiple failed repair attempts, it enters a major degradation.
- Major degradation: The program as a whole switches to a large agentic loop, completely attempting to accomplish the original task goal in agent mode (corresponding to the situation where a new path is replanned). Of course, it considers the parts already completed by the original workflow and executes the remaining actions based on this foundation.

When building with AmphiLoop, selecting option 2 in the “Project Mode” step will generate a program with the amphiflow architecture. As shown below:

[<img src="/assets/images_amphiloop/en/choose_option_1.png" width="90%" />](/assets/images_amphiloop/en/choose_option_1.png)

Of course, the above introduction omits some details. The workflow mode does not necessarily require specifying a **concrete** path during programming; it can also contain a dynamic algorithm to dynamically calculate a path. But the **key point here is: for the workflow mode, if an obstacle appearing in the execution path is unexpected, it cannot be resolved. However, the agent mode can handle unexpected obstacles or situations**.

### Advantages of Amphiflow

Amphiflow can simultaneously take the advantages of both workflow and agent modes:
- When operating within the expected range, it uses workflow mode, which is stable, controllable, does not rely on LLMs, and saves tokens.
- When unexpected environmental changes occur, it switches to agent mode to autonomously respond to unexpected situations, bypass obstacles, or notify humans to resolve them.

It is precisely because this new architecture simultaneously possesses the characteristics of both workflow and agent modes that it is called Amphiflow (amphibious flow).

### Implementation Principles of Amphiflow

To clearly explain the implementation principles of Amphiflow, two aspects need to be addressed:
1. How are workflow mode and agent mode fused together?
2. How does the switch to agent mode occur when workflow mode encounters an error?

For question 1, two concepts need to be involved:
- **The "Observe - Think - Act" cycle.** In the AmphiLoop architecture, both modes can be uniformly attributed to this cycle. They share the "Observation" and "Act" phase, but the "Think" phase is independent for each.
- **Decoupling Decision from Execution**. In the AmphiLoop architecture, the independent "Think" phase of the two modes produces independent decisions.

The core implementation code involved here is basically in the `bridgic-amphibious` module's `_amphibious_automa.py` file. The link is:

> https://github.com/bitsky-tech/bridgic/blob/main/packages/bridgic-amphibious/bridgic/amphibious/_amphibious_automa.py

#### The "Observe - Think - Act" Cycle

It is usually easy to understand the agent mode as a loop:
- **Observe: Process the observed raw data into a form suitable for thinking**. This step can also be considered a **"perception" process**.
- **Think: Produce a decision to determine the next action**. For the agent mode, this decision is produced by the LLM. This step can also be considered a **"cognition" process**.
- **Act: Invoke tools to affect the environment**.

This "Observe - Think - Act" cycle of the agent mode is implemented in the `_run_once` method:

[<img src="/assets/images_amphiflow_tech/code_agent_run_once.png" width="90%" />](/assets/images_amphiflow_tech/code_agent_run_once.png)

A unique point in the AmphiLoop architecture is that the workflow is also implemented as an "Observe - Think - Act" cycle. How is this achieved? First, observation and action behave the same as in agent mode, where the implementation code is located in the `_run_workflow` method:

[<img src="/assets/images_amphiflow_tech/code_run_workflow.png" width="90%" />](/assets/images_amphiflow_tech/code_run_workflow.png)

Note that in the above code, there are only observation and action steps. The crucial variable, `decision`, is no longer generated by the LLM, but instead by the workflow itself. The code is as follows:

[<img src="/assets/images_amphiflow_tech/code_call_on_workflow.png" width="90%" />](/assets/images_amphiflow_tech/code_call_on_workflow.png)

The above code calls `on_workflow` to produce a generator, and then in a loop calls the `__anext__` and `asend` primitives to get an `item` from the generator each iteration (which contains `item.decision`). This loop forms the "Observe - Think - Act" cycle of the workflow mode.

#### Decoupling Decision from Execution

Earlier, we saw the **"Observe - Think - Act" cycle of the workflow mode. The "Think" phase is implicitly expressed by the workflow code**. Let's look at a concrete implementation example of `on_workflow`:

[<img src="/assets/images_amphiflow_tech/code_on_workflow_example.png" width="90%" />](/assets/images_amphiflow_tech/code_on_workflow_example.png)

This code is not from the AmphiLoop framework itself, but is code generated by AmphiLoop each time based on the specific task description (`TASK.md`) guided generation. Therefore, `on_workflow` describes the execution steps of the specific task.

Python's `yield` syntax is used here, indicating that when the `on_workflow` method is executed, it does not mean the true execution of the task. The actual execution is deferred to the `_action` method in the `_run_workflow` method mentioned earlier. **With this technical means, the execution of the workflow also manifests as an "Observe - Think - Act" cycle. Each cycle produces a decision (encapsulated in `ActionCall`)**.

It should also be noted that this code is not just a sequence of `ActionCall` actions; it can also contain dynamic logic (branches and loops), such as the `for` loop in the code above. **This indicates that AmphiLoop's workflow is different from simple record-and-replay; it is a truly dynamic program**.

#### Switching Modes

Based on the previous "Observe - Think - Act" cycle and the architecture of decoupling decision from execution, the workflow mode can automatically switch to agent mode when an error occurs.

[<img src="/assets/images_amphiflow_tech/code_mode_switch.png" width="90%" />](/assets/images_amphiflow_tech/code_mode_switch.png)

In the above code, `self.snapshot` plus `self._run` is a minor degradation, equivalent to executing an agent in an independent context. The goal is to fix the error in the step that went wrong and then execute it (here, `decision.step_content` comes from the `description` parameter of the `ActionCall` from earlier). This allows switching back to workflow mode to continue execution after the fix.

`self.on_agent(ctx)` is a major degradation, equivalent to launching an agent whose goal is the original task goal and which shares the context with the original workflow.

### Summary

AmphiLoop and the amphiflow architecture it introduces are future architectures derived from the autonomous advantages of agents and the deterministic advantages of traditional software. They target the core problems of today's AI technology being uncontrollable, unstable, and extremely token-consuming, and are theoretically conducive to promoting the adoption of AI technology in broader and deeper scenarios.

### Community

(1) We have created a new Discord community. Please visit the following address to participate in the discussion:

> <https://discord.gg/4NyKjXGKEh>

(2) New X (Twitter) account (this will be the main channel for posting version update dynamics in the future):

> <https://x.com/bridgic>

(The End)

**Other Selected Articles**:

* [Building Agents in Amphibious Mode, a Different Solution from OpenClaw/Hermes](https://mp.weixin.qq.com/s/KKHWWzJqeKR1fF6EsXheLQ)
* [【Open Source】A Brand New Browser Toolset + Skills Designed for the "Pathfinding + Coding" Paradigm](https://mp.weixin.qq.com/s/1nstbS6EBEuZAJQL8o4ASg)
* [New Year, Let's Talk About AI and Humanities](https://mp.weixin.qq.com/s/8rQ8a5M35ymod_gjP1JChg)
* [The AI Agent Era May Reset to Zero Starting from 2026](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [【Open Source】An AI Framework I Personally Developed, and the Thoughts Behind It](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [The Software Development Paradigm in the AI Agent Era](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [The Concept, Autonomy Level, and Abstraction Level of AI Agents](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [Science Popularization: Disassembling the Probability Principles Behind LLMs](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [What Exactly Does the Most Important Paper in the Distributed Domain Talk About?](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
