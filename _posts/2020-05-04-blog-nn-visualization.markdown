---
layout: post
category: "other"
title: "看得见的机器学习：零基础看懂神经网络"
date: 2020-05-04 00:00:00 +0800
published: true
---

关于机器学习，有一个古老的笑话：

> Machine learning is like highschool sex. Everyone says they do it, nobody really does, and no one knows what it actually is. [1]

翻译过来意思大概是：
> 机器学习就像高中生的性爱。每个人都说他们做了，但其实没有人真的做了，也没有人真正知道它到底是什么。

<!--more-->

总之，在某种程度上，机器学习确实有很多晦涩难懂的部分。虽然借助TensorFlow、sklearn等工具，机器学习模型以及神经网络通常能被快速地运行起来，但真正弄清背后发生了什么，仍然不是一件容易的事。在本篇文章中，我会试图用直观的方式来解释神经网络。俗话说，「耳听为虚，眼见为实」，本文的目标就是，利用「可视化」的方法，让你亲眼「看到」神经网络在运行时到底做了什么。

本文不会出现一个公式，希望非技术人员也能看懂。希望如此^-^

### 最简单的神经网络

当今在图像识别中使用的深度神经网络，都发展出了非常复杂的网络结构，网络层次多达几十层，模型参数多达数十万个。这样的神经网络理解起来，难度极大。

因此，我们由简入繁，先从最简单的情况入手。

首先，我们考虑一个简单的「二分类」问题。下面展示了一个随机生成的数据集：

[<img src="/assets/photos_nn_visualization/two-clusters-examples.png" style="width:600px" alt="两组二维随机数据" />](/assets/photos_nn_visualization/two-clusters-examples.png)

上图展示的是总共160个点（包括红色和蓝色），每个点代表一个数据样本。显然，每个样本包含2个特征，这样每个样本才能够在一个二维坐标系中用一个点来表示。红色的点表示该样本属于第1个分类，而蓝色的点表示该样本属于第2个分类。

二分类问题可以理解成：训练出一个分类模型，把上图中160个样本组成的训练集按所属分类分成两份。注意：这个表述并不是很严谨。上图中的样本只是用于训练，而训练出来的模型应该能对「不属于」这个训练集的其它样本进行分类（不过我们现在不关注这一点，可以先忽略掉这个表述上的细节）。

为了完成这个二分类任务，我们有很多种机器学习模型可供选择。但现在我们的目的是为了研究神经网络，所以我们可以设计一个最简单的神经网络，来解决这个分类问题。如下图：

[<img src="/assets/photos_nn_visualization/nn-simplest-2-layers.png" style="width:500px" alt="最简单的神经网络" />](/assets/photos_nn_visualization/nn-simplest-2-layers.png)

这个神经网络几乎没法再简单了，只有1个输入层和1个输出层，总共只有3个神经元。

经过简单的数学分析就容易看出，这个只有2层的神经网络模型，其实等同于传统机器学习的LR模型（逻辑回归）。也就是说，这是个线性分类器，对它的训练相当于在前面那个二维坐标平面中寻找一条直线，将红色点和蓝色点分开。

根据红色点和蓝色点的位置分布，我们很容易看出，这样的一条直线，很容易找出来（或学习出来）。实际上，上图中这个简单的神经网络，经过训练很容易就能达到100%的分类准确率(accuracy)。

现在，假设我们的数据集变成了下面的样子（红色点分成了两簇，分列蓝色点左右）：

[<img src="/assets/photos_nn_visualization/three-clusters-examples.png" style="width:600px" alt="三组二维随机数据" />](/assets/photos_nn_visualization/three-clusters-examples.png)

如果我们还是使用前面的2层的神经网络，试图画一条直线来把红色点和蓝色点分开，显然就做不到了。我们说，现在这个分成三簇的数据集已经不是「线性可分」的了。实际上，针对最新的这个数据集，前面这个只有2层的神经网络，不管你怎么训练，都只能达到60%~70%左右的分类准确率。

为了提高分类的准确率，比较直观的想法也许是画一条曲线，这样才能把红色点和蓝色点彻底分开。这相当于要对原始输入数据做非线性变换。在神经网络中，我们可以通过增加一个隐藏层(hidden layer)来完成这种非线性变换。修改后的神经网络如下图：

[<img src="/assets/photos_nn_visualization/nn-with-hidden-layer.png" style="width:600px" alt="带隐藏层的神经网络" />](/assets/photos_nn_visualization/nn-with-hidden-layer.png)

我们看到，修改后的神经网络增加了一层包含2个sigmoid神经元的隐藏层；而输入层和隐藏层之间是全连接的。实际上，当我们重新训练这个带隐藏层的神经网络时，会发现分类的准确率又提升到了100%（或者非常接近100%）。这是为什么呢？

我们可以这样来看待神经网络的计算：每经过一层网络，相当于将样本空间（当然也包括其中的每个样本数据）进行了一次变换。也就是说，输入的样本数据，经过中间的隐藏层时，做了一次变换。而且，由于隐藏层的激活函数使用的是sigmoid，所以这个变换是一个非线性变换。

那么，很自然的一个问题是，经过了隐藏层的这一次非线性变换，输入样本变成什么样了呢？下面，我们把隐藏层的2个神经元的输出画到了下图中：

[<img src="/assets/photos_nn_visualization/hidden-layer-outputs.png" style="width:600px" alt="隐藏层输出可视化" />](/assets/photos_nn_visualization/hidden-layer-outputs.png)

我们发现了一个有趣的现象：变换后的样本数据点，还是分成了三簇，但红色点再也不是分列蓝色点的两侧了。两簇红色点被分别逼到了一个角落里，而蓝色点被逼到了另外一个不同的角落里。很容易看出，现在这个图变成「线性可分」的了。而隐藏层的输出数据，再经过神经网络最后一个输出层的处理，刚好相当于经过了一个线性分类器，很容易用一条直线把红色点和蓝色点分开了。

从隐藏层的输出图像，我们还能发现一些细节：
* 所有的数据坐标（不管是X轴还是Y轴），都落在了(0,1)区间内。因为sigmoid激活函数的特性，正是把实数域映射到(0,1)之间。
* 我们发现，所有的数据都落在某个角落里。这不是偶然，还是因为sigmoid激活函数的特性。当充分训练到sigmoid神经元「饱和」时，它一般是会输出接近0或1的值，而极少可能输出一个接近(0,1)中间的值。

总结一下：从前面的分析，我们大概可以看到这样一个变换过程，就是输入样本在原始空间内本来不是「线性可分」的，而经过了隐藏层的变换处理后，变得「线性可分」了；最后再经过输出层的一次线性分类，成功完成了二分类任务。

当然，这个例子非常简单，只是最简单的神经网络结构。但即使是更复杂的神经网络，原理也是类似的，输入样本每经过一层网络的变换处理，都变得比原来更「可分」一些。我们接下来就看一个稍微复杂一点的例子。

### 手写数字识别


### 从低维到高维


### 高维数据的可视化


### 小结


（正文完）

##### 参考文献：

* [1] <https://github.com/antirez/neural-redis>{:target="_blank"}


**其它精选文章**：

* [卓越的人和普通的人到底区别在哪？](https://mp.weixin.qq.com/s/7xXtmQ31ZkaPcFXVej4Yeg)
* [用统计学的观点看世界：从找不到东西说起](https://mp.weixin.qq.com/s/W6hSnQPiZD1tKAou3YgDQQ)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s/_Emd5WoQrXJ3oRGxenTl7A)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)
* [做技术的五比一原则](https://mp.weixin.qq.com/s/VfePdDnKkOlsxdm_slQp5g)
* [知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)