---
layout: post
category: "other"
title: "给普通人看的机器学习原理(一)"
date: 2019-12-03 00:00:00 +0800
published: true
---

相信大家已经注意到了，本文的题目强调了：这是写给「普通人」看的机器学习原理。

为什么一定要写给普通人看呢？我想了想，大致有三个原因：

<!--more-->

1. 机器学习算法非常有意思，它代表了一种全新的思维方式，跟传统的基于if/else的规则迥然不同。站在机器学习的视角，这个世界的一切都是概率。我们大家都有必要了解一下这种新的思维方式是怎么运作的。
2. 普通大众对于机器学习算法的认识，长期以来形成了两种截然相反的观点。其中一种观点认为，机器学习意味着艰深的数学，那是「科学家」们搞的东西，普通人根本无法理解；另一种观点则认为，机器学习的门槛已经变得如此之低了，一个普通工程师通过拖拖拽拽就能建起一个模型，把数据灌进去然后就能跑起来，整个过程根本不需要数学。甚至业界的算法专家们也戏谑地称自己为「调参工程师」。这些观点到底对不对，我们先不做过多的探讨。然而关键的一点是，一件事，我们如果不了解它，就永远无法形成正确的认识，更无法向大众澄清它的真相。
3. 把专业的知识讲给普通人，这本身就是很有挑战性的事情。要做到既深入（不是浮于表面），又能通俗易懂，这中间需要填补大量的认知gap。所以说，这件事本身就很酷！

我曾经在《[分层的概念——认知的基石](https://mp.weixin.qq.com/s/yLdRuhIWfLOnLPJSDocEhQ){:target="_blank"}》一文中跟大家讨论过，知识是分层次的。因此，在开始之前，我们必须首先决定当前这篇文章的描述是建立在一个什么样的层次基础之上的。同一件事，对一名工程师和一名非技术人员，讲述的方式肯定截然不同。综合考虑，我还是认为，读者应该主要是从事编程工作的工程师，否则，文章的描述就不可能深入下去。在这里，我们假设，作为读者的你，对于如何把一个实际问题转变成可以运行的程序应该有足够的经验，而且曾经在大学课程里面至少学过高等数学和概率论。

还有一个问题：机器学习的概念如此广泛，我们从哪里开始呢？

如果我们从基础概念开始讲起，那么文章会变得冗长无趣，而且跟任何一本机器学习的教科书没有太大区别。任何可能涉及抽象概念的讨论，总得有个切入点。因此，我打算采取一个比较新的方式。接下来，我会选取一个具体的机器学习模型，以解释清楚它的工作原理为目标，来组织文章的章节。这个模型不能太简单，只有这样，我们才有机会在讨论它的过程中，涉及到机器学习的各个方面。总之，我选择的模型是一个非常有代表性的机器学习模型——GBDT。这个模型将很多看似不相干的众多概念结合了起来，最终形成了一个完整的模型。选择它还有一个原因，那就是GBDT在推荐系统的设计中有着非常广泛的应用。

虽然我们从具体的模型开始，但是，等我们真正地深入讨论之后就会发现，具体的模型其实并不重要，重要的是蕴含在整个过程里的设计思想。它们才是我们更需要关注的东西。所以，在组织这篇文字的时候，我内心始终抱着这样一个信念：讲清楚具体模型的运作原理并不是本文的真正目的（虽然它对于明确本文的讨论方向起着至关重要的作用），理清背后的整体脉络和思想才是更重要的。

此外，还有一个令人举棋不定的决策要做，那就是文章中到底要不要出现数学公式？显然，每出现一个公式，都会吓跑一部分读者，最终本文也就没法完成“给普通人讲述机器学习”的目标了。但是，机器学习毕竟是与数学关联比较紧密的学科。如果本文一个公式也没有，那么它就跟一般的科普文章没有什么区别了。我还是希望能跟读者进行稍微深入一些的探讨的。况且，在很多时候，一个公式真的胜过千言万语。

经过仔细权衡，我力求在文中少出现公式。即使无法避免，我也努力让出现的公式尽量简单易懂。而且，就算你跳过它，也希望能继续阅读。

### GBDT概述

GBDT这个模型有很多不同的名字：
* GBDT: Gradient Boosted Decision Tree；
* GBRT: Gradient Boosted Regression Tree；
* GBM: Gradient Boosting Machine；
* MART: Multiple Additive Regression Tree；

除了这些名字之外，有时候它也被简单地称为Gradient Tree Boosting。这个模型真正的出处，是来源于Jerome H. Friedman的一篇论文：
* 《Greedy Function Approximation: A Gradient Boosting Machine》

从论文的题目可以看出，作者对于这个模型的称呼是GBM。

GBDT相对来说是一个比较复杂的模型，它的理论构成如下图所示：

[<img src="/assets/photos_gbdt/gbdt_components.png" style="width:400px" alt="GDBT的理论构成" />](/assets/photos_gbdt/gbdt_components.png)

上图的意思大致是说：
* Gradient Descent加上Boosting就得到了Gradient Boosting；
* Gradient Boosting再加上Regression Tree就得到了GBDT；

因此，为了理解GBDT，必须首先理解Gradient Descent、Boosting以及Regression Tree等这些概念。现在，我们先试图用一句话来高度概括一下这几个概念，然后各章节再分别详细介绍。
* Gradient Descent (梯度下降)：通过沿梯度相反的方向进行迭代来解决数值优化 (Numerical Optimization) 问题的一种方法。
* Boosting: 一种串行地生成基学习器 (base learner) 的集成学习 (Ensemble Learning) 方法。
* Gradient Boosting: 在函数空间 (function space) 使用梯度下降，从而将Boosting方法扩展到任意可微的损失函数 (differentiable loss function) 的一个算法框架。
* Regression Tree (回归树): 用于解决回归问题的一种决策树 (Decision Tree) 模型。
* GBDT: 将上述诸多概念结合起来的集大成者——将Gradient Boosting算法框架中的基学习器指定为回归树 (Regression Tree) 之后得到的具体模型。

### 优化理论

根据本文开头设定的方向，为了解释清楚GBDT这个模型，我们首先要解释清楚的是梯度下降 (Gradient Descent) 这个概念。而要解释清楚这个概念，我们首先要从优化问题 (Optimization Problem) 说起。

无论是在自然界和人类社会中，还是在人类建造的系统中，优化都是一种普遍存在的行为。下面是一些例子：
* 在一个隔绝的系统中，大量分子相互作用，最终会达到所有电子总势能最小化的状态[1]。物理系统总是趋向于向着能量最小的状态演化，这是自然界的优化过程。
* 投资者不断优化投资组合，以追求收益的最大化。
* 一个城域交通系统，追求的是整个城市交通输送效率的最大化。
* 线上广告系统，追求的是整个系统对于广告投放的ROI (收入减去成本) 的最大化。

所有这些例子，都可以抽象成数学上的优化问题来描述。按照维基百科的解释，下面这几个概念是等同的：
* 优化 (Optimization)
* 数值优化 (Numerical Optimization)
* 数学优化 (Mathematical Optimization) 
* 数学规划 (Mathematical Programming) 

它们都可以在数学上表示从备选集合中选出最佳元素的过程[2]。为避免混乱，我们接下来统一使用「优化」这个词汇。

举一个简单的例子，假设我们有一个目标函数：

*f(x) = 2x<sup>2</sup> + 8x + 11*

现在要求使 *f(x)* 最小，那么*x*取值应该是多少？这就是一个优化的例子。如果用公式来表达这个优化目标，应该表示成：

[<img src="/assets/photos_gbdt/equation_f_min.png" style="height:32px" alt="min f(x)公式" />](/assets/photos_gbdt/equation_f_min.png) 或 [<img src="/assets/photos_gbdt/equation2_f_min.png" style="height:32px" alt="min f(x)公式" />](/assets/photos_gbdt/equation2_f_min.png) 

上面这个式子表示，*x*是自变量，取值可以在整个实数域*R*上变化。而问题的目标是：找到使得 *f(x)* 达到最小值的*x*的值是多少。

假设 *x<sup>\*</sup>* 是该优化问题的解，那么可以表达成：

[<img src="/assets/photos_gbdt/equation_f_argmin.png" style="height:32px" alt="argmin f(x)公式" />](/assets/photos_gbdt/equation_f_argmin.png)

在这个例子中，*f(x)*的表达式比较简单，我们根据中学的数学知识就知道它是一个开口向上的抛物线。如下图所示：

[<img src="/assets/photos_gbdt/fx_parabola_plot.png" style="width:400px" alt="f(x)抛物线图像" />](/assets/photos_gbdt/fx_parabola_plot.png)

从上面的函数图像很容易看出来，使得 *f(x)* 取最小值的点就是图中的红点，即：

*x<sup>\*</sup> = -2*

那么，这个解是通过怎样的计算过程得到的呢？我们知道，一个连续函数在极值点的导数为零，可以利用这个特性来求解：

[<img src="/assets/photos_gbdt/x_solution_evaluation.png" style="width:200px" alt="x求解过程" />](/assets/photos_gbdt/x_solution_evaluation.png)

由于这个目标函数比较简单，所以我们很容易通过计算和推导得到了问题的解。这种通过严格的数学推导能够得到的解，可以称为解析解 (analytical solution)或闭式解 (closed-form solution)。

但是，对于实际中的优化问题，由于两个原因，无法通过推导闭式解的方式来解决：
1. 实际中的目标函数通常都非常复杂，根本求不出闭式解；
2. 优化问题通常是需要借助计算机来求解的，而计算机虽然善于做数值计算，却不善于做公式推导。

因此，解决优化问题的通用算法一般都是基于迭代的思路，通过一步一步的近似计算，逐步逼近真实的解。

在具体介绍这种迭代算法之前，我们先看一下优化问题的一般形式[1]：

[<img src="/assets/photos_gbdt/equation_numeric_optimization.png" style="width:260px" alt="优化问题表达式" />](/assets/photos_gbdt/equation_numeric_optimization.png)

上面的数学表达式的含义是：
* ***x***是*n*维向量{*x*<sub>1</sub>, *x*<sub>2</sub>, ..., *x*<sub>*n*</sub>}<sup>T</sup>，表示自变量；
* *f(x)*是优化的目标函数，它是*n*元函数的形式；
* *c<sub>i</sub>*表示约束函数，它们定义了自变量***x***必须遵守的等式条件或不等式条件。当然，一个优化问题也可以不包含任何约束条件。

解决优化问题的迭代算法，都是类似这样的过程：
* 给定自变量的一个初始值***x***<sub>0</sub>；
* 从初始值出发，算法一步一步地迭代，每次都在*n*维空间中移动一小步。这样就形成了一系列迭代的变量值：***x***<sub>1</sub>, ***x***<sub>2</sub>, ..., ***x***<sub>*k*</sub>, ***x***<sub>*k+1*</sub>, ... 最终逐渐接近真实的解***x***<sup>\*</sup>。

（注意这里的每个迭代值***x***<sub>*k*</sub>，都是一个*n*维向量，所以用黑体字型来表示）

在迭代算法中，有一个关键的问题需要解决：在从第*k*步向第*k*+1步迭代的时候，如何决定往哪个方向移动？显然，根据前面我们对优化问题的定义，应该往目标函数变小的方向移动，即：

[<img src="/assets/photos_gbdt/iterate_fx_compare.png" style="height:32px" alt="f(x)迭代比较" />](/assets/photos_gbdt/iterate_fx_compare.png)

回到前面抛物线的目标函数，这时自变量*x*退化到一维（标量）。假设根据迭代算法我们当前走到了第*k*步，如下图：

[<img src="/assets/photos_gbdt/fx_parabola_tangent_plot2.png" style="width:400px" alt="f(x)抛物线切线迭代图像" />](/assets/photos_gbdt/fx_parabola_tangent_plot2.png)

图中红色箭头是*x<sub>k</sub>*点的切线方向，绿色箭头则是切线的相反方向。显然，下一步（第*k+1*步）应该沿着切线的相反方向迭代，去寻找*x<sub>k+1</sub>*的位置。这样，就能让目标函数*f(x)*的值越来越小，最终抵达最优解*x<sup>\*</sup>*。

而对于一般的目标函数，自变量***x***是一个*n*维向量，对应一个*n*维空间。由于在多维空间中函数的图像是无法在视觉上体现的，所以我们先考虑***x***是二维向量的情况（也就有两个自变量），这时函数的图像是三维空间中的一个曲面。如下图：

[<img src="/assets/photos_gbdt/valley_with_ball_v2.png" style="width:480px" alt="梯度下降在三维空间的演示" />](/assets/photos_gbdt/valley_with_ball_v2.png)

与前面抛物线图像的情况类似，一次迭代沿着图中绿色箭头的方向进行，就像一个小球在山谷的斜坡上向下滚动，最终到达谷底（最优解）。

前面的两个例子比较形象地展示了迭代的方向。可以看出，迭代应该是向着与最优解不断接近的方向进行。但这个方向的选择在复杂的多维空间中并不容易。比如，在下图的函数图像中，曲面的「地形」比较复杂，每次的迭代方向就不是那么容易选择的了。

[<img src="/assets/photos_gbdt/complex_plot.png" style="width:400px" alt="复杂曲面在三维空间的演示" />](/assets/photos_gbdt/complex_plot.png)

在优化理论中，选择迭代方向的策略有两大类：
* line search (线搜索);
* trust region (信赖域)。

Line search的策略是每一步迭代都选择一个固定的方向（通过近似计算使得目标函数变小的方向），然后沿着这个方向前进一个合适的步长。而对于前进方向的选择上，又可以细分成不同的方法，下面简要介绍一下：
* 梯度下降法 (Gradient Descent)。这个就是在本章开头我们原本打算要解释的那个概念（终于讲到它了）。这种方法会选择沿梯度（一阶导数）相反的方向作为下一步迭代的方向，然后沿着这个方向走尽量远的距离，直到目标函数的值不再下降为止。因此，这种方法也可以称为最速下降法 (Steepest Descent)。
* 牛顿法 (Newton method)。在选择迭代方向的时候考虑二阶导数的信息（计算过程依赖Hessian矩阵）。
* 拟牛顿法 (Quasi-Newton method)。在选择迭代方向的时候通过近似计算避免了直接计算Hessian矩阵。

而trust region这种策略与line search不同，它在每一步迭代时并不会选择固定的前进方向，而是根据当前迭代位置选择一个近似区域。这个近似区域就被称为信赖区域 (trust region)，因为在这个区域内可以做一些与目标函数近似的计算，如果区域太大这种近似就不成立了。trust region这种策略会先固定住信赖区域的大小，然后在这个区域内选择一个使目标函数变小的前进方向（近似计算）；如果发现计算中使用的近似计算与目标函数差距太大了，就减小信赖区域的大小，重新进行计算。

总体来讲，由于实际中目标函数都比较复杂，我们没法直接利用目标函数的全局信息来找到最优解。因此，迭代的时候，我们只能根据当前迭代位置附近的局部信息来做近似计算。这些局部信息可能来自于一阶导数（梯度）或二阶导数（Hessian矩阵），而近似计算则是基于泰勒公式 (Taylor formula)。不管是line search还是trust region，它们都可能使用同样的这些局部信息和近似计算方法。不过在基于近似计算的结果选择迭代方向和步长的时候，line search和trust region采取了两种不同的策略：line search在每一步迭代中固定住前进方向，然后试探合适的步长；而trust region则在每一步迭代中尝试同时选择前进方向和步长大小，而一旦信赖区域大小发生变化，前进方向和步长也都发生变化。

我们用下面的概念图来做一个总结：

[<img src="/assets/photos_gbdt/concepts_optimization.png" style="width:600px" alt="优化理论概念图" />](/assets/photos_gbdt/concepts_optimization.png)

上图有一个有趣的现象值得注意：越是向左，越是偏理论；越是向右，越是偏实现。左边是数学理论，而右边则是可以在计算机上实现的算法。

### 机器学习的概率表达

严格来说，优化并不属于机器学习的范畴，而是机器学习的解法需要的理论。

### 机器学习的优化目标

优化的关键是要有一个目标，这个目标怎么来的？

（正文完）

##### 参考文献：

* [1] Jorge Nocedal, Stephen J. Wright, "Numerical Optimization", Second Edition.
* [2] <https://en.wikipedia.org/wiki/Mathematical_optimization>{:target="_blank"}

**其它精选文章**：

* [用统计学的观点看世界：从找不到东西说起](https://mp.weixin.qq.com/s/W6hSnQPiZD1tKAou3YgDQQ)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261626&idx=1&sn=6b32cc7a7a62bee303a8d1c4952d9031&chksm=844791e3b33018f595efabf6edbaa257dc6c5f7fe705e417b6fb7ac81cd94e48d384a694640f#rd)
* [光年之外的世界](https://mp.weixin.qq.com/s/zUgMSqI8QhhrQ_sy_zhzKg)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261555&idx=1&sn=3662a2635ecf6f67185abfd697b1057c&chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)