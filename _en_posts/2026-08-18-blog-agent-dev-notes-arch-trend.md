---
layout: post
category: ml
lang: en
translation_key: durable-agent-architecture
translation_url: /posts/blog-agent-dev-notes-arch-trend.html
permalink: /en/posts/blog-agent-dev-notes-arch-trend.html
title: "AI Agent Development Notes: Toward Durable Architectures"
date: 2026-08-18 00:00:00 +0800
published: true
---

While developing [Bridgic Agent](https://github.com/bitsky-tech/bridgic-agent), I have gradually come to see a trend in the evolution of agent architecture. To sum up my conclusion in one sentence: agent architectures are evolving toward **durability**.

<!--more-->

This is not merely the simple observation that today's agents need longer-lasting memory.

This article may be somewhat abstract, but I will use as many concrete cases as possible to illustrate the idea.

### What Is Wrong with Earlier Agent Architectures?

Agents first entered the public eye as a new product category largely through command-line interfaces (CLI). Early versions of Claude Code, for example, were programming tools for engineers. Because engineers already did much of their work in terminals, this product form felt natural. These CLI tools also offered relatively rich text-based user interfaces (TUI), making the interaction experience “good enough” for engineers.

Such a tool is still essentially like any other command-line program on Linux: you launch it when you need it and exit after the work is done. While using it, you can interact with only one session at a time. To interact with another session, you must first switch to it. This, too, feels natural in a TUI.

But once agents evolved into desktop applications, a new issue emerged: you could open multiple sessions at the same time and start a new task in each one. In other words, you could interact with multiple sessions concurrently. This is the most natural interaction model for a desktop product.

On the surface, there seems to be nothing wrong with that. Yet allowing users to interact with multiple sessions at once introduces a fundamental change to desktop applications: the lifecycle of the application no longer matches the lifecycle of any individual session. Unlike with a TUI, you do not have to exit one session before opening another.

Now suppose a session reaches a human-in-the-loop operation—perhaps a permission request or a question asking the user to choose from several options. That session may wait there indefinitely. Technically, this creates two further problems:

1. The waiting session cannot release its resources.
2. If the application process restarts, the unfinished session cannot restore itself to its previous state.

This is why most desktop agents on the market currently rely on a temporary compromise. If an agent is displaying an interactive screen or dialog and waiting for the user to choose, trying to quit the application triggers a warning that unfinished sessions still exist and asks whether you really want to exit. If you insist, the session data will be lost.

This situation is partly a consequence of the evolutionary path of agents as a product category. Because agents originated in TUIs and began as client-side products, many companies inherited a client-based architecture. During the human interaction described above, the entire session technically remains suspended at an `await`, which blocks at least that coroutine. Much of its state therefore stays in memory, which is why the session cannot be fully restored after the process restarts.

Of course, even desktop products that allow multiple sessions rarely have a very large number of sessions open for a single user, and fewer still happen to be waiting for human input. The problem is therefore not yet severe, and temporary workarounds are usually sufficient.

However, agents face another trend: they will move to the cloud. Everyone has a strong desire for their agent to keep working even after their computer is turned off. This raises another question: why, in the AI era, did agents emerge as desktop applications rather than as cloud services accessed through a browser, as in the internet era? There are at least two reasons:

- The first is cost. Agent execution is an extremely long-running process, whereas traditional internet requests finish in milliseconds. Long-running tasks consume enormous cloud resources. When the business model is still unclear, offering agents as a cloud-hosted service is economically unattractive.
- The second is dependency on the environment. An agent works much like someone operating a computer, and the tasks it handles are often tightly coupled to the user's local desktop environment and files.

In short, the rapid development of AI applications has contributed to the popularity of Electron and the widespread adoption of `TS` in the AI community (where `Python` had previously dominated). At the same time, this has become a constraint—a classic case of path dependence.

In any event, the transition from desktop agents to cloud agents is unavoidable. The demand will persist, and there are again two reasons:

- Costs are high today, but sufficiently strong business models may eventually support them. Costs will inevitably fall as well.
- Serious enterprise agents intended for production are more likely to run in isolated cloud environments, where consistent and stable execution can be guaranteed.

And here is the problem: once agents move to the cloud, the two issues that were relatively minor on the desktop—releasing resources and persisting state across restarts—become critical.

### What Will Future Agent Architectures Look Like?

**First, the frontend and backend will be decoupled.**

When the frontend is waiting for a user response, the underlying session should not remain blocked in memory. Instead, it should be able to **pause/stop**, release its resources, and then resume after the user completes the interaction.

As discussed above, this is not a particularly serious issue in a desktop client. In the design of [Bridgic Agent](https://github.com/bitsky-tech/bridgic-agent), however, it is a major concern. Why? One of Bridgic Agent's most important design principles is **“Agent-Led, Not Human-Driven.”** At the implementation level, this means the agent is particularly good at proactively initiating an interaction and then waiting for the user to make a choice, as in the example below:

[<img src="/assets/images_arch_trend/en/ask-human-example.webp" width="80%" />](/assets/images_arch_trend/en/ask-human-example.webp)

It even proactively asks the user to confirm mistakes or omissions in a task description. In the following example, when I entered the task, I referred to a status field in a Feishu spreadsheet. I had remembered it incorrectly: no such field existed in the spreadsheet. The actual field was named `order_status` (not `status`). Bridgic Agent proactively displayed the interaction below and prompted me to choose the correct field. This level of fine-grained control is clearly essential if an agent is to complete tasks in real-world scenarios.

[<img src="/assets/images_arch_trend/en/confirm-about-wrong-fields.webp" width="80%" />](/assets/images_arch_trend/en/confirm-about-wrong-fields.webp)

This creates a problem. A Bridgic Agent user is likely to run multiple sessions concurrently, and each session is highly likely to pause for user input. Therefore, although Bridgic Agent is currently only a desktop application, its architecture must solve this problem. Keep one fact in mind: a user may never respond to an interaction request in a particular session. They may simply abandon it, since they can always open a new session and run the task again.

Solving this problem requires decoupling the frontend architecture from the backend architecture. A pure client architecture that couples the frontend interface and its underlying session into a single control flow suspended by `await` is simply not viable.

**Second, the agent lifecycle will be decoupled from its in-memory state.**

Put another way, the agent will be **durable**. Closing the application will no longer mean that the agent behind it ceases to exist.

Why? Because this matches the user's perspective.

Consider a more extreme case. Suppose you are interacting through a browser with an agent deployed in the cloud. Before the task is complete, your interaction may be intermittent: you might return hours or even days later to continue. As we have already seen, the need to release resources means the agent cannot remain in memory waiting for you the entire time. Yet you would not conclude that it no longer exists simply because it was evicted from memory in the meantime.

Agents will perform increasingly long-running tasks in the real world. Consider another scenario in which agents collaborate with people: an agent joins a group chat, listens to its messages, and responds when appropriate. When the group is quiet, the agent clearly does not need to occupy memory while it waits. Doing so would waste tremendous resources—imagine having a large number of groups to monitor.

Bridgic Agent faces the same concrete problem. As noted earlier, when it proactively interacts with a person, it must be able to stop rather than wait in memory. Stopping means releasing memory. It means persisting state. And it means restoring that state—including conversation data, interaction state, and other information—after receiving the user's response.

Persistence, interruption, and recovery deserve a few more words. Agent runtimes may be naturally suited to these capabilities. From first principles, program code is difficult to persist, interrupt, and restore. Earlier software architectures could certainly serialize and deserialize state, but scaling that approach across environments with complex dependencies could become a nightmare. Agent systems improve the situation because nearly all their context is text.

Moreover, from the user's perspective, **it is impossible to say** exactly when a conversation with an agent has ended. You can return at any time and continue the interaction. In this sense, we can regard the agent as an entity that conceptually persists indefinitely, with a lifecycle decoupled from whether it currently occupies memory.

### Summary

To summarize, future agent architectures will decouple the frontend from the backend and support interruption, persistence, and restart at any time. In other words, the agent's lifecycle will be decoupled from its in-memory state. I call an architecture with these properties a **durable agent architecture**.

Such an architecture is clearly better suited to cloud deployment. It also works equally well for clients and the cloud. Most agents on the market have not yet reached this point because of path dependence and because the problem has not been severe enough so far.

From the beginning, however, [Bridgic Agent](https://github.com/bitsky-tech/bridgic-agent) has embraced the principle that **“Agent-Led, Not Human-Driven.”** This creates a more urgent need for such an architecture. As a result, Bridgic Agent's architecture is now only one step away from that of a true cloud agent.

This article has examined one direction in the evolution of agent architecture and how it manifests in a real development project. It is certainly not the whole story of agents.

I will continue sharing my experience developing agents. Comments and discussion are welcome.

(End)

**More selected articles:**

- [After Months in Seclusion, I’m Officially Releasing an Open-Source Agent—and Starting to “/build”](https://zhangtielei.com/posts/blog-bridgic-agent-workflow-builder.html)
- [Why Can Agents and Workflows Be Unified in a Single Architecture?](https://zhangtielei.com/en/posts/blog-amphiflow-implementation.html)
- [Beyond Autonomous: Why I’m Building an Amphibious Agent](https://zhangtielei.com/en/posts/blog-bridgic-amphiloop-en.html)
- [A Lunar New Year Conversation About AI and the Humanities](https://mp.weixin.qq.com/s/8rQ8a5M35ymod_gjP1JChg)
- [The AI Agent Era May Reset in 2026](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
- [The Software Development Paradigm in the AI Agent Era](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
- [AI Agents: Concepts, Levels of Autonomy, and Layers of Abstraction](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
- [A Primer: The Probability Behind LLMs](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
- [What Does the Most Important Paper in Distributed Systems Actually Say?](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
