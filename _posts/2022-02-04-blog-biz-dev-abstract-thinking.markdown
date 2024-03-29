---
layout: post
category: "essay"
title: "谈谈业务开发中的抽象思维"
date: 2022-02-04 00:00:00 +0800
published: true
---

在两年前的文章中《[在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)》，我把技术人员的开发工作归成了两类：「业务开发」和「专业技术开发」。今天，我们再回过头来仔细审视一下其中的「业务开发」工作，聊一聊这类工作中所需要的抽象思维能力是怎样的，以及怎么培养这些能力。

<!--more-->

就像在之前那篇文章中所讨论的，随着社会分工越来越专业化，现实企业对于「业务开发」的职位需求量，是远远超过「专业技术开发」的。也就是说，互联网的大部分开发人员，应该都属于「业务开发」人员。

而对于「业务开发」人员来说，很多人都面临一个比较棘手的个人成长问题：怎样从日复一日的、看似枯燥的业务逻辑开发中提升自己？特别是在述职、晋升，以及面试找工作的时候，如果被问及“你做的事情技术亮点是什么？”大部分同学都无法给出一个很好的答案。

### 为什么要重视抽象思维能力？

《论语》中有这么一段话，是关于学习方法的：
> 子曰：“赐也，女(rǔ)以予为多学而识(zhì)之者与？”对曰：“然，非与？”曰：“非也，予一以贯之。” 

翻译成现代汉语：
> 孔子说：“子贡呀，你以为我是多学而博记的人吗？”子贡回答说：“是的，难道不是这样吗？”孔子说：“不是的，我是用一个基本观念把它们贯穿起来。” 

子贡是谁呢？他是孔子的得意门生（全名叫端木赐），在《论语》中出镜率很高。子贡不仅在学业、政绩方面颇有建树，而且在理财经商上非常成功。所以司马迁在《史记·货殖列传》中花了相当的笔墨对子贡的事迹进行记载，说他富致千金，是孔子弟子中的首富。

然而，像子贡这样一个能力很强的人，他对于自己的老师——孔子，却赞誉有加。他曾经说，孔子的学问就像“万仞宫墙”一般，一般人根本“不得其门而入”。实际上，孔子死后，子贡威望很高，孔子能当圣人，儒学成为显学，很大程度上就与子贡的后期宣传有关。

孔子的学问，到底好在哪里呢？答案就在前面我们引用的对话中。子贡以为老师肯定是学了很多很多知识，然后把它们都记下来了，所以才很有学问。但孔子说，不对，我之所以学问渊博，不是因为我一直埋头苦读或者记性好，而是因为我掌握了一种方法，用一个基本观念把大量的知识都贯穿起来了。即所谓的“一以贯之”。

我们先不管圣人所说的这个「基本观念」到底指的是什么，这个故事至少告诉我们一个道理：博闻强记自然是好的，但并不是提高学习效率的关键。为什么有些人对于事物的理解可以快速直达本质，关键在于他们掌握了某种“一以贯之”的认知方法。显然，这种方法是抽象的，是不随具体学问而变化的，能够帮助人们提升学习和认知效率。这是古人在两千多年前就已经悟出的道理。

映射到我们的工作中，工程师开发各种业务逻辑，内容千差万别，看似摸不到规律，但我们还是应该努力寻找事物背后相通的那些道理，站在更高的层面去运用抽象思维，才能最终达到融会贯通的境界。

与「专业技术开发」相比，「业务开发」似乎用不到太多高深的技术，很多情况下也不涉及高并发、大流量、低延迟等要求，只要了解了数据库存取、微服务调用、消息队列收发等一些基础的编程知识，就差不多能胜任工作了。很多同学可能会觉得，「业务开发」很快就会碰到技术瓶颈，在晋升或述职的时候也难以总结出亮点。但是，这类工作的难点就在于业务本身的复杂性上，对业务逻辑本身的抽象和建模，正是体现亮点的地方。

实际上，培养自己的抽象思维能力，不仅仅是为了晋升或述职，更是为了提升自己的底层思考能力。当然，对晋升或述职来说，平时不烧香，临时抱佛脚，肯定是不行的。因此，接下来我们就一起来讨论一下，如何在日常工作中有意识地培养抽象思维能力。

### 抽象思维的三个阶段

抽象思维似乎只可意会，不可言传，而天马行空的讨论更容易使人摸不着头脑。因此，为了让接下来的讨论更清晰，我们先限定在业务开发领域，并将抽象思维拆解为三个阶段：
* 第一阶段：经验归纳。
* 第二阶段：建模。
* 第三阶段：高层抽象。

当你在某个业务领域工作了两三年之后，你积累的领域经验会助你进入抽象思维的第一阶段。你已经获得了足够多的信息，在对这些信息进行适当的归纳加工之后，就能得到属于你自己的独有的经验。你可以利用这些经验来指导解决工作中的问题，同时这些经验也自然成为你和刚步入职场的毕业生之间的竞争优势。

举几个例子。

假设你做过任务激励系统，那么自然就能理解设计类似的系统需要考虑的方方面面。比如，业务触发事件怎样收集，各种类型的任务（生产类、消费类、下载类任务等等）怎样匹配，它们各有哪些特殊性，奖励怎样发放，任务如何组合，上层的高级玩法有哪些，等等等等。

再假设你做过消息通知系统，那么你肯定已经考虑过一系列相关的设计问题。比如，消息触达渠道有哪些，消息模板怎么设计，消息各个维度的频控规则怎样实现，消息的触达、已读、点击等反馈指标如何追踪和计算，消息的批量发送任务如何管理，消息的个性化推送需要考虑哪些因素，等等等等。

再举一个非业务领域的例子，比如系统稳定性治理工作，看似琐碎，但仔细总结也是能归纳出很多经验的。包括流程制定、灰度发布、预案机制、限流降级、监控完善、隔离机制、冗余备份、应急工具，等等等等。

你可以把这些经验画成框图，制成思维导图，或整理成其他任何形式。面对类似问题的时候，你相当于有了一个框子，或者一个思维模板，把问题套进去。这些经验起到的关键作用在于，它们让你有机会从最开始就考虑全面，而不仅仅是碰到一个问题解决一个问题。所以说，这是一个「做加法」的过程。

接下来，当你碰到的业务系统足够复杂的时候，特别是业务实体足够多的时候（比如各种CRM系统），上面这些经验可能就不够用了。你需要因地制宜，根据实际中独特的业务流程需要，进行建模（modeling），构建出领域模型（domain model）。这就进入了第二个阶段。

到底什么是模型？提到模型这个词，很多人会想到机器学习模型。除此之外，还有很多非技术性的模型，比如业务模型、商业模型、财务模型，等等。它们有一点相似性，都是对事物某一方面的本质的一种刻画。比如，机器学习模型本质上就是用模型表达的概率分布去刻画真实世界的概率分布。

我们这里谈的业务开发中的领域模型，用于刻画业务流程的本质，更接近领域驱动设计（DDD）里面的概念。它有两个典型的特点：
* 第一，通常是符合面向对象的描述方式的。我们对于事务的认识，关键在于把握概念本身，以及各个概念之间的关系，这很自然地就与面向对象的设计思想相一致。随着我们对于概念之间关系的理解逐步深入，新的概念得以涌现出来，或者从旧的概念中分化出来，或者把本来混淆一起的、实际上有细微差别的概念识别出来。当根据分析的需要，把大的概念拆分得更细，一直拆分到恰好能够描述概念之间的关系的粒度为止，我们就得到了一个领域模型。
* 第二，领域模型与它所刻画的业务流程之间，存在一个相互影响的互动过程。它并非对于业务流程的简单的单向刻画。通常来说，业务流程梳理得越是清楚，描述它的领域模型也会变得精简；反之，领域模型设计过于复杂，也会给业务流程带来更多的成本。

总之，当我们面对业务系统未知的复杂性，现成的经验积累就不够用了。我们需要不断建模，这本质上是一个「创造」的过程。

第三个阶段，是应对系统规模化的必然做法。有两个因素决定了我们需要「高层抽象」：
* 单个系统的规模变得足够大。随着一个系统的规模变得越来越庞大，即使它的每一个细节都能够被领域模型刻画出来，但也终于会庞大到无法让人全局把握的程度。
* 在一个规模足够大的业务中，我们最终需要面对多个系统，而不仅仅是一个系统。通常每个系统都会形成自己的领域模型。所以，我们需要通过类似系统大图的方式来理顺领域模型之间的关系。

第三个阶段讲的是一种相对比较高级的思维方式，也是一个合格的产品架构师或软件架构师所应该达到的层次。我们需要有取舍地丢弃掉单个领域模型的一些内部细节，在更高的层面上去把握它们之间的关系。所谓抽象思维，是需要我们对大量的信息进行概括的（而非简单的堆砌），只有这样才能减轻思维的负担，不至于陷入繁复的细节里面去，也才有可能对规模化的系统或事物形成整体的把握。从这个意义上说，这是一个「做减法」的过程。

总之，抽象思维的三个阶段具有某种内在联系。第一阶段，人们解决问题很自然的一个做法，就是求诸自己的经验积累。第二阶段，面对新的复杂性，现成的经验已经不work了，也就需要一种思维方式能直达事物本质，这就是建模。第三阶段，单个模型只能让我们把握局部，要想把握全局，就需要通过高层抽象，构建出系统大图。

值得注意的是，现实中的业务系统，很多都是随着业务不断发展一点一点「堆」起来的。在系统一路发展的过程中，可能既没有经验积累作为指引，也没有细致的建模分析对系统设计进行推敲，更没有系统大图来指导全局。可见，掌握了这三个阶段的抽象思维方法，对于系统设计和其演化路径将会产生重大的影响。

### 技术之外

从前文的描述中我们发现，这些抽象思维能力，其实可以延伸到技术之外。

首先，对于抽象思维的第二和第三阶段，即使我们已经限定在了业务开发领域，但所有的描述几乎都没有涉及具体的技术。这些都是抽象的思维模式，完全不涉及缓存、数据库以及各种技术参数。

我们在《[在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)》一文中提及过，「业务开发」人员需要面对整个世界的复杂度。这些复杂度当然不仅仅是技术层面的。对于系统建模和高层抽象的思维方式，其实也适用于规模庞大的组织。比如，面对上万人的公司组织，最高管理层如何才能对这个组织的现状获得有效的把握？显然，把每个员工负责的事情罗列出来是不够的，细节堆砌在一起并不会自动形成抽象的认知。而是需要按照业务领域层层划分组织，公司划分为事业部，事业部下面再划分二级部门，依次类推，才能在各个层面去理解整个组织的样貌。管理层对于组织结构的设计，也有点类似于前面说的抽象思维的第二和第三阶段：理顺每个部门内部的微观结构（系统建模），同时理顺部门之间的协作关系（高层抽象）。部门内协调一致，部门间协调一致，整个组织也就协调一致。

通常来说，第一阶段的经验归纳，是相对容易做到的，是普通人也可以企及的思维高度。只要我们认真做好手头的工作，就事论事地保持积累和总结，就总能有所收获。如果做得好，把这些经验进行系统化的记录、归纳、整理、分类，对于较复杂的、专业性较强的业务领域，甚至可以著书立说。

第二阶段的建模思维，则难度较大。它有一点哲学认识论的味道，涉及到人类知识如何对客观世界进行刻画的问题。类比到物理学领域，物理定律对于客观的物理规律的描绘，实际上也是一种「建模」。按照《[知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)》一文中对于知识的分类，建模的过程同时涉及到知识的归纳和演绎。

再来简单对比一下：经验归纳的思维方法，主要是对信息进行收集，以及简单的加工整理；而建模方法考验的主要是逻辑思维过程。并不是说信息对于建模不再重要，而是说，在促成模型形成的各种因素中，对于信息的了解，所占比重已大幅下降。建模可以看作是对信息的深度加工整理。

而第三阶段的高层抽象，主要是为了应对问题规模，把握更「大」的东西。首先，并不是所有人都会遇到规模足够大的问题需要解决。只有对于规模庞大的公司、组织、政府机构，这种思维方式才是必不可少的。更进一步，高层抽象需要处理模型和模型之间，甚至是体系和体系之间的关系问题。还是类比到物理学领域，如果把牛顿运动定律、相对论和量子力学看作三个不同的模型，那么高层抽象就相当于要描述清楚这三个理论体系之间的关系。类似这种「大一统」的思维方式，自然是抽象层次最高，也最难的。

回到业务开发的领域，我们在《[在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)》一文中有个有趣的描述，「业务开发」人员是领着程序员的工资，操着CEO的心。但这也正说明了「业务开发」是一件没有边界的工作。当你折腾完一个领域再折腾另一个的时候，经过不断的自我思考和抽象，逐渐开始有能力把握越来越大的问题规模，说不定哪一天你就真的成为CEO了。

（正文完）

**其它精选文章**：

* [知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)
* [在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
* [条分缕析分布式：到底什么是一致性？](https://mp.weixin.qq.com/s/qnvl_msvw0XL7hFezo2F4w)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [看得见的机器学习：零基础看懂神经网络](https://mp.weixin.qq.com/s/chHSDuwg20LyOcuAr26MXQ)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)