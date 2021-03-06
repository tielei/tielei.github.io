---
layout: post
category: "essay"
title: "用统计学的观点看世界：从找不到东西说起"
date: 2019-07-28 00:00:00 +0800
published: true
---

在家里，妻子总是埋怨我找不到东西。于是我辩称，很多东西并不是我放的，找不到很正常啊。每当这个时候，她总是一脸不屑地说，很多东西也不是她放的，但为什么她很快就能找到？

<!--more-->

我回想了一下，事实似乎真的如此。不管是孩子的日常衣物、水杯文具，还是常年不用的证照、文件之类，她总能快速地把它翻找出来。按她的说法，你自己“扒拉扒拉”不就找到了吗？

根据我惯常的程序员思维，这种到处“扒拉扒拉”找东西的方式，属于最原始的遍历搜索，应该很低效才对啊。其实在房间里找东西，有点类似于在一大堆数据中查找你想要的那份数据，要想效率高，怎么着也得建个索引吧。但家里显然不存在这么一个「索引」。

妻子找东西似乎是依靠着某种直觉的。这不太科学。

直到有一天，我在维基百科上发现了一个统计学理论，才豁然开朗。这个理论叫做**贝叶斯搜索理论** ([Bayesian search theory](https://en.wikipedia.org/wiki/Bayesian_search_theory){:target="_blank"})[1]，恰好是一个关于「如何找东西」的理论。当然，它并没有直接告诉我们如何在房间里找东西，而是给出了一套统计学方法，在实际中经常应用在「失物搜索」领域，比如在海面上打捞沉船或者飞机残骸等等。

这个理论是1966年由美国海军的一位科学家发明出来的。

当时正值冷战期间。美国空军的一架B-52G轰炸机，携带了四枚氢弹，在西班牙海岸外的地中海上空执行一个例行的飞行活动。谁也没有想到，轰炸机在空中加油时竟与加油机相撞，结果飞机解体，那四枚氢弹也自然不知所踪。其中的三枚氢弹很快就被搜索小组找到了，但第四枚始终下落不明。

为了寻找第四枚氢弹，美国海军派出了一个技术援助小组。小组成员中就包含这位科学家——[约翰·克雷文](https://en.wikipedia.org/wiki/John_P._Craven){:target="_blank"}博士[2]。想象一下当时的情景：这第四枚失踪的氢弹，肯定是落到了一个出人意料的地方，否则它早就像前三枚氢弹一样被找到了。但可能性实在太多了，它可能落到了西班牙海岸边某个地方，也可能落到了地中海广阔的水域中。总之，寻找氢弹的任务如同大海捞针，看起来根本无从下手。

但约翰·克雷文独辟蹊径，依据**贝叶斯推断** ([Bayesian inference](https://en.wikipedia.org/wiki/Bayesian_inference){:target="_blank"})[3]的数学原理，发明出了贝叶斯搜索理论这一套方法，并在这个理论的指导下成功找到了第四枚氢弹。

这一套方法后来又曾多次在海上搜救中派上用场。比如，1968年美国海军寻找[失联的核潜艇](https://en.wikipedia.org/wiki/USS_Scorpion_%28SSN-589%29){:target="_blank"}[4]，2009年[法航447航班空难](https://en.wikipedia.org/wiki/Air_France_Flight_447){:target="_blank"}后寻找黑匣子[5]，都是依靠这套方法。没错，2014年的[马航370失联](https://en.wikipedia.org/wiki/Malaysia_Airlines_Flight_370){:target="_blank"}后的搜救工作[6]，也使用了这套方法（但不幸没有找到）。

这个**贝叶斯搜索理论**听起来似乎有些神奇，那它到底是怎么做的呢？

实际上，它的关键在于能够将不确定的信息，包括根据经验做出的各种猜测，都用数字化的方式量化出来，并根据搜索过程中的阶段性成果不断地对这些数字进行修正。为了理解这个理论的细节，我们需要一点点概率论和统计学的知识作为铺垫。因此，现在我们先不过早地深入到这些细节中去，而是先来讲一个看似无关的小故事，然后我们再回过头来看这个理论。

### 一个关于决策和可信度的小故事

假设有一家公司，由于市场环境的变化，亟待进行业务转型。如果转型失败，公司就面临倒闭。

现在假设你临危受命，被董事会任命为公司的CEO，来领导公司的转型。经过多方调研以及与公司同事们的讨论，你发现有一个新的业务方向值得去尝试。但是，向这个新业务的转型需要巨额的前期投资。接着你发现，根据公司目前的财务状况，你只能一次性成功，根本没有试错的机会。也就是说，如果选错了投入的方向，那么公司最后的资本就会耗尽，也就彻底没有翻盘的机会了。所以，你现在需要做一个决策：到底要不要投入这个新业务？

这个决策责任重大，你自己也有点拿不准。于是，你找来了公司核心的两位元老 (A和B)，打算听取他们的意见。

很不幸，A和B对于新的业务方向意见不同。A比较乐观，而B比较保守。他们分别做出了如下的论断：

* *R*<sub>*A*</sub>: 公司有九成的把握可以在新业务上取得成功；
* *R*<sub>*B*</sub>: 公司只有三成的把握可以在新业务上取得成功；

这时候你迫切地想知道谁的论断更准确一点，更接近实际情况。但是，由于你刚刚上任不久，以前跟A和B从来没有打过交道，所以你对于他们谁说的话更靠谱完全没有任何信息。把这个情况定量地表达出来，你可以说，A和B做出的两个论断可信度都是50%。这个可信度可以用概率表示出来，如下：

* *P*(*R*<sub>*A*</sub>) = 0.5
* *P*(*R*<sub>*B*</sub>) = 0.5

这样呢，公司在新业务上转型成功和失败的概率，针对A和B的两个论断，可以分别表达成条件概率的形式：

* *P*(转型成功\|*R*<sub>*A*</sub>) = 0.9
* *P*(转型失败\|*R*<sub>*A*</sub>) = 1 - 0.9 = 0.1
* *P*(转型成功\|*R*<sub>*B*</sub>) = 0.3
* *P*(转型失败\|*R*<sub>*B*</sub>) = 1 - 0.3 = 0.7

上面四个式子具体是什么含义呢？我们稍微解释一下。以第一个式子为例，*P*(转型成功\|*R*<sub>*A*</sub>) = 0.9，表示“如果A的论断是成立，那么转型成功的概率是0.9”。其它几个式子的含义依此类推。

所谓兼听则明，偏信则暗，于是你想综合考虑一下两个人的论断，通过计算来确定公司转型成功和失败的概率最终分别是多少。这需要使用**全概率公式**([Law of total probability](https://en.wikipedia.org/wiki/Law_of_total_probability){:target="_blank"})[7]：

* *P*(转型成功) = *P*(转型成功\|*R*<sub>*A*</sub>) * *P*(*R*<sub>*A*</sub>) + *P*(转型成功\|*R*<sub>*B*</sub>) * *P*(*R*<sub>*B*</sub>) = 0.6
* *P*(转型失败) = *P*(转型失败\|*R*<sub>*A*</sub>) * *P*(*R*<sub>*A*</sub>) + *P*(转型失败\|*R*<sub>*B*</sub>) * *P*(*R*<sub>*B*</sub>) = 0.4

好了，现在你得到了一个结论：公司在这个新业务上转型成功的可能性是60%。不算太高，但暂时也没有找到更好的方向可供选择，所以你决定放手一搏，驱动整个公司进行转型。

一年后，毫无疑问，你会得到两个结果中的一个：转型成功了，或者，转型失败了。

先考虑转型失败的情况，这时候公司的钱花光了，面临倒闭。但是，你想吸取教训，对决策过程进行一下复盘。基于现在最新的结果（转型失败了），你可以重新计算当初A和B的两个论断的可信度，这需要用到**贝叶斯定理**([Bayes' theorem](https://en.wikipedia.org/wiki/Bayes%27_theorem){:target="_blank"})[8]：

* *P*(*R*<sub>*A*</sub>\|转型失败) = *P*(转型失败\|*R*<sub>*A*</sub>) * *P*(*R*<sub>*A*</sub>) / *P*(转型失败) = 0.125
* *P*(*R*<sub>*B*</sub>\|转型失败) = *P*(转型失败\|*R*<sub>*B*</sub>) * *P*(*R*<sub>*B*</sub>) / *P*(转型失败) = 0.875

这两个式子的意思是说，根据现在转型失败这一客观事实，你修正了当初两个论断的可信度。它们不再分别是50%了，而是A的论断的可信度急剧降低，变成了12.5%，而B的论断的可信度升高到87.5%。这里可能有人会说，现在转型失败已经是确凿的事实了，为什么A的论断的可信度没有降低到零啊？这个倒也很好理解，因为A并没有说转型会100%成功。就算A的论断完全符合实际，公司仍有10%的概率会转型失败。但是不管怎么说，从概率上判断，我们可以认为，A说的话没有那么靠谱了。这可能会促使你对A产生一个很不好的印象，也许你以后再也不想跟A一起玩了。

再来考虑一下转型成功的情况。这时候公司找到了新的业务方向，前景一片光明。你同样想对决策过程进行一下复盘。基于现在最新的结果（转型成功了），你重新计算了当初A和B的两个论断的可信度（还是基于**贝叶斯定理**）：

* *P*(*R*<sub>*A*</sub>\|转型成功) = *P*(转型成功\|*R*<sub>*A*</sub>) * *P*(*R*<sub>*A*</sub>) / *P*(转型成功) = 0.75
* *P*(*R*<sub>*B*</sub>\|转型成功) = *P*(转型成功\|*R*<sub>*B*</sub>) * *P*(*R*<sub>*B*</sub>) / *P*(转型成功) = 0.25

这意味着，在你心目中，A的靠谱程度升高到75%，而B的靠谱程度降低到25%。假设后来公司又有新的决策需要制定，而A和B又给出了不同的论断，分别记为：

* *S*<sub>*A*</sub>
* *S*<sub>*B*</sub>

那么这一次，你可以把上一次对A和B论断的可信度的最新估计，当做初始的可信度估计，即：

* *P*(*S*<sub>*A*</sub>) = 0.75
* *P*(*S*<sub>*B*</sub>) = 0.25

然后，你就可以像上次决策过程一样，进行新一轮的计算评估了。并且，在决策的执行结果出来后，可以继续调整对于A和B论断的可信度的估计值。

### 贝叶斯学派和贝叶斯推断

在上面这个小故事中，我们已经不自觉地将「可信度」这个看似主观的概念用概率来表达了。那么这个做法合不合理呢？

实际上，统计学是分为两个学派的：频率学派和贝叶斯学派，它们对于概率的解释完全不同。

频率学派将概率解释成随机事件不断重复试验得到的频率的极限值。典型的例子就是掷硬币。如果我们不停地重复进行掷硬币的试验，那么出现正面的次数与总的试验次数的比值（也就是正面出现的频率），随着试验次数的增加，将无限趋近于正面出现的概率。

贝叶斯学派则将概率解释成对于不确定性的度量。在这种观点下，任何未知量都可以看做一个随机变量。在实际中，存在很多不确定性的事件，并不能用大量重复试验来表达。这种情况用贝叶斯概率来表达就比较方便。比如，明天的降水概率；再比如，北极冰帽在十年后完全消失的概率。我们前面将「可信度」表达成概率，显然也是指的贝叶斯概率。

**贝叶斯定理**在频率学派和贝叶斯学派中都是被承认的。但是，它在贝叶斯学派中有特殊的意义。我们通常说，**贝叶斯定理**能将一个**先验概率** ([prior probability](https://en.wikipedia.org/wiki/Prior_probability){:target="_blank"})[9]转换成一个**后验概率** ([posterior probability](https://en.wikipedia.org/wiki/Posterior_probability){:target="_blank"})[10]，而这个转换是由于观测到了新的数据才发生的。

具体到上面的小故事中，最开始对于A和B的两个论断的可信度分别进行的估计，即*P*(*R*<sub>*A*</sub>)和*P*(*R*<sub>*B*</sub>)，就属于**先验概率**，因为这两个估计值是在观测到任何真实数据之前对于「可信度」的一种预估。也就是说，得到这两个值只能根据个人经验和历史资料，在预估的时候并没有任何真实发生的客观事实可以用来佐证这两个论断的可信程度。

一旦某些相关的事件真实发生了（转型成功了或失败了），那么对于原本A和B这种**先验**的论断就产生了某种程度佐证，你就能基于真实发生的客观事实，对他们的论断的可信程度重新进行计算。我们前面看到了，这个重新计算的过程是基于**贝叶斯定理**的，而重新计算之后得到的概率，*P*(*R*<sub>*A*</sub>\|转型成功)、*P*(*R*<sub>*B*</sub>\|转型成功)、*P*(*R*<sub>*A*</sub>\|转型失败)、*P*(*R*<sub>*B*</sub>\|转型失败)，都属于**后验概率**。这个后验概率，是同时考虑了先验信息（基于个人经验和历史资料）和真实数据（转型的结果，是成功了还是失败了），才得到的更准确的一种估计。

一旦你得到了后验概率，那么在下一次随机试验的时候（对应到前面故事里的下一次决策），你就能把这个「更准确」的后验概率当成这次随机试验的先验概率，即*P*(*S*<sub>*A*</sub>)和*P*(*S*<sub>*B*</sub>)，进行新一轮的推断。当新的试验结果（即下一次决策的执行结果）被观测到的时候，你可以再次基于贝叶斯定理把最新的先验概率转换成后验概率。

这个过程可以不断重复进行。随着观测到的数据越来越多，得到的后验概率也就越来越接近真实情况。通过不断地观测，不断地将先验概率转成后验概率，从而不断接近真实概率的这种方法，就称为**贝叶斯推断** ([Bayesian inference](https://en.wikipedia.org/wiki/Bayesian_inference){:target="_blank"})[3]。

### 回到贝叶斯搜索理论

文章开头我们已经提到，**贝叶斯搜索理论**是依据**贝叶斯推断**的原理进行「失物搜索」的一种系统化的方法。这种方法与前面小故事中的决策过程有一点类似，都是先预估出先验概率，然后根据事情的实际进展情况来一步步修正这个概率，从而得到越来越准确的后验概率。

**[贝叶斯搜索理论](https://en.wikipedia.org/wiki/Bayesian_search_theory){:target="_blank"}**[1]具体的步骤可以这样概括：

1. 先根据丢失物品可能发生的各种情况提出尽可能多的假设。在前面氢弹丢失的例子中，搜索专家考虑了氢弹坠落后可能发生的各种情况，比如氢弹有两个降落伞，它们在坠落过程中可能都打开了，也可能都没打开，或者只打开了一个。再比如，氢弹可能会以不同的角度坠落。
2. 针对每一种假设，对丢失物品所处的可能位置预估一个概率分布。简单来说，就是预估一下物品可能会落到哪些位置区域，同时也需要预估出物品处于每个位置区域的概率分别是多少。这个概率就是**先验概率**，需要借助专家的经验才能预估得比较准确。专家可能会考虑飞机的飞行方向、当时的风向、海洋的水流情况等多种因素，来估计这些概率。可以想象，落在每个位置的概率肯定不尽相同。
* 用概率来定量表达就是：*P*(*X*) = *p*，表示物品落在位置*X*的概率是*p*。这个就是先验概率。
3. 对每个可能的位置*X*，估计出这样一个条件概率：如果丢失的物品确实位于*X*附近，那么在位置*X*附近找到该物品的概率会是多少。这里需要注意，就算丢失的物品真的落在了*X*附近，也不能保证就肯定能找到它，这还受限于搜索的成本和技术手段。想象一下在大海中打捞失物，物品入水越深，打捞上来的希望越是渺茫。所以这里仍然需要用概率来表达。
* 定义事件*S*<sub>*X*</sub>表示在位置*X*成功找到了失物；
* 定义事件*F*<sub>*X*</sub>表示在位置*X*未能找到失物；
* 那么，这一步骤里提到的条件概率可以表示成：*P*(*S*<sub>*X*</sub>\|*X*) = *q*。这个式子表示的含义是：如果丢失的物品确实位于*X*附近，那么在位置*X*附近能成功找到该物品的概率是*q*。
4. 结合前面第2步和第3步的两个概率（相乘），对于每一个位置*X*，都计算出在该位置能成功找到丢失物品的概率。
* 这个概率表达成：*P*(*S*<sub>*X*</sub>, *X*) = *P*(*X*) \* *P*(*S*<sub>*X*</sub>\|*X*) = *pq*。
5. 按照丢失物品在各个位置可能被找到的概率（即第4步得到的概率）从高到低排序，依次在各个位置展开搜索。
6. 如果在位置*X*附近找到了物品，那么搜索结束。反之，如果在位置*X*附近没有找到丢失的物品（即发生了事件*F*<sub>*X*</sub>），那说明丢失的物品落在位置*X*的概率急剧降低。接下来就需要对物品落在各个位置的概率重新进行调整，然后返回第4步确定下一个位置继续搜索。

最后一步中，对概率进行调整的过程，其实就是根据贝叶斯定理计算后验概率的过程。具体如下：

对于刚刚搜索失败的这个位置*X*来说，我们需要计算的后验概率是*P*(*X*\|*F*<sub>*X*</sub>)。为了计算这个概率，我们先计算：
* *P*(*F*<sub>*X*</sub>, *X*) = *P*(*X*) \* *P*(*F*<sub>*X*</sub>\|*X*) = *p*(1-*q*)
* *P*(*F*<sub>*X*</sub>) = *P*(*X*) \* *P*(*F*<sub>*X*</sub>\|*X*) + *P*{物品不在*X*} \* *P*{*F*<sub>*X*</sub>\|物品不在*X*} = *p* \* (1 - *q*) + (1 - *p*) \* 1 = 1 - *pq*

至此，我们很容易得到后验概率：

*P*(*X*\|*F*<sub>*X*</sub>) = *P*(*F*<sub>*X*</sub>, *X*) / *P*(*F*<sub>*X*</sub>) = *p*(1 - *q*)/(1 - *pq*)

现在，在进行下一轮搜索之前，我们需要把物品落在位置*X*的概率的值，也就是*p*，替换成*P*(*X*\|*F*<sub>*X*</sub>)的值。从上面的式子结果很容易看出来，这个值跟原来的*p*相比，变小了。

而对于其它的任一位置*Y*来说，物品落在*Y*的概率，经过这轮在位置*X*的搜索失败之后，会变大。计算过程跟上面的类似，这里就不详细列出了。只给出具体的计算结果：如果原来物品落在位置*Y*的先验概率是*r*，那么它应该在下一轮搜索之前更新成*r*/(1 - *pq*)。显然，这个值比*r*要大。

现在，对于文章开头碰到的问题，为什么在家里妻子总是能比我更快地找到东西，我们已经能比较清楚地回答了。原因就在于，妻子在对先验概率的估计上更准确。对于要找的某个东西，它可能是在卧室的床头柜里，还是在客厅电视旁边的抽屉里，或者是被放到了阳台上——到底在哪里找到它的概率更高，诸如此类的信息，显然妻子掌握了更准确的先验信息。

### 统计学的观点

根据前面的分析，找东西是个概率问题。概率就是存在不确定性的。实际上，我们生活中有太多的事情都没法精确地描述，都是充满了不确定性的。

那对于不确定性的问题，如何来定量地分析呢？这时候统计学就派上用场了。贝叶斯搜索理论正是这样一种用统计学的方法来解决不确定性问题的典型例子。这也是为什么生活中的很多问题用一般的编程手段解决不了，但用机器学习却可以解决。因为机器学习是基于统计学的。

在机器学习中，为了对模型的参数进行估计，比较自然的做法是采取**最大后验估计**([Maximum A Posteriori Estimation](https://en.wikipedia.org/wiki/Maximum_a_posteriori_estimation){:target="_blank"}, MAP)[11]。这种做法也是利用**贝叶斯推断**的原理，先对模型参数有一个先验的估计，然后在训练数据被灌进来之后，就得到了后验估计。沿着这种思路，甚至有更极端的方法，比如，**sequential Bayesian inference**，用于实时在线的模型训练。这种方法就是每次只处理一个样本数据（或一小批数据），并不停地更新参数的估计值。每次处理样本数据的过程，其实就是把先验变成后验的过程；然后在处理下一个样本数据之前，再把后验当做是下一次估计的先验。这个不断重复的过程，跟本文前面讨论的失物搜索的过程非常类似。

贝叶斯推断，在生活中有着广泛的应用。像很多人都在玩的德州扑克，本质上也是一个贝叶斯推断的问题。你开始只能看到自己的两张底牌，根据它们的大小，你会对于自己取胜的概率有一个初步的估计，这是先验概率。随着每一张公共牌的亮出，你不断得到新的信息，然后你利用这些信息调整估计，得到后验概率。当然，能够影响你对于取胜概率进行估计的信息，除了牌的大小，还有各玩家的场上表现。有经验的玩家就会利用这一点，故意透露一些虚假信息，来误导你对于取胜概率的估计。

同时，贝叶斯推断也饱含着生活的智慧。就像本文前面那个关于决策和可信度的小故事一样，首先它表明了信用体系的运作原理。一个人的信用是如何建立起来的？正所谓听其言而观其行，一个人的言论靠不靠谱，要看他说的话能不能在实际中兑现。每兑现一次，就相当于用一个确凿的事实对这个人的靠谱程度进行了一次佐证。随着兑现的次数增加，别人对他的可信度的估计也会越来越高。反之，他如果总是言行不一，那么可信度就会逐渐降低。

另外，贝叶斯推断的原理也告诫我们，我们应该根据实际发生的一个个新的事实，来不断调整自己的后验估计。有时候，这相当于在改变自己的观念。如果一个人思想中主观的成分过多，就会对于一些新的“发现”视而不见，从不调整自己的后验估计，而是完全按照“惯性”思维行事。这样的人就会故步自封，永远跟不上时代的步伐。

最后，对于先验概率的估计，是需要依据个人经验和历史资料做出的。针对具体的某个领域，往往专家会比普通人估计得更准，因为他们的经验更丰富，掌握了更贴近事实的先验信息。这至少说明，专家还是很重要的。回到文章开头在家里找东西的例子，这意味着，在处理家庭事务方面，毫无疑问，妻子就是这样的一名专家^-^

（正文完）

##### 参考文献：

* [1] <https://en.wikipedia.org/wiki/Bayesian_search_theory>{:target="_blank"}
* [2] <https://en.wikipedia.org/wiki/John_P._Craven>{:target="_blank"}
* [3] <https://en.wikipedia.org/wiki/Bayesian_inference>{:target="_blank"}
* [4] <https://en.wikipedia.org/wiki/USS_Scorpion_%28SSN-589%29>{:target="_blank"}
* [5] <https://en.wikipedia.org/wiki/Air_France_Flight_447>{:target="_blank"}
* [6] <https://en.wikipedia.org/wiki/Malaysia_Airlines_Flight_370>{:target="_blank"}
* [7] <https://en.wikipedia.org/wiki/Law_of_total_probability>{:target="_blank"}
* [8] <https://en.wikipedia.org/wiki/Bayes%27_theorem>{:target="_blank"}
* [9] <https://en.wikipedia.org/wiki/Prior_probability>{:target="_blank"}
* [10] <https://en.wikipedia.org/wiki/Posterior_probability>{:target="_blank"}
* [11] <https://en.wikipedia.org/wiki/Maximum_a_posteriori_estimation>{:target="_blank"}

**其它精选文章**：

* [万物有灵之精灵之恋](https://mp.weixin.qq.com/s/TqpkiSWHSmhY0RIG_sKCQA)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261626&idx=1&sn=6b32cc7a7a62bee303a8d1c4952d9031&chksm=844791e3b33018f595efabf6edbaa257dc6c5f7fe705e417b6fb7ac81cd94e48d384a694640f#rd)
* [光年之外的世界](https://mp.weixin.qq.com/s/zUgMSqI8QhhrQ_sy_zhzKg)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261555&idx=1&sn=3662a2635ecf6f67185abfd697b1057c&chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)