---
layout: post
category: "android"
title: "OpenGL ES和坐标变换（二）"
date: 2017-09-18 00:00:01 +0800
published: true
---

本文是《[OpenGL ES和坐标变换](/posts/blog-opengl-transformations-1.html)》系列文章的第二篇。在本文中，我们将集中讨论以下内容：

1. 首先，以Demo程序中的代码为例，介绍model、view、projection三个变换在Android中如何用代码来表达。
2. 介绍相关理论，推导一下model变换中的缩放(scaling)和平移(translation)这两个变换的计算过程。由于旋转(rotation)这个话题比较复杂，我们留在下一篇再讨论。
3. 我们分析一下Android中的缩放(scaling)和平移(translation)变换的具体实现，将前面的理论推导同代码实现相互印证，以加深理解。

<!--more-->

著名数学家高斯曾经说过一句话：“当一幢建筑物完成时，应该把脚手架拆除干净。”他说这话的意思是，一个新的数学理论一旦推导完成，他就会把多余的东西（比如灵感来源、直观的想法、中间走过的弯路、多余的推导计算等等）统统删掉，只把最终得到的最简洁的定理和结论公布出来。高斯的理由是，「脚手架」会影响理论的美感。但是，没有这些所谓的「脚手架」，后人就很难理解他的理论。从学习的角度来说，这些「脚手架」却是大大的有用。试想，只是看到一座宏伟的大厦，你并不能学会如何去建造它。

本文为了让细节讨论更加清楚，当然不会按照高斯的这种风格。相反，在本文接下来的描述中，我们会尽量详尽地说明每一步推导过程，并尽可能把推导的思路说清楚。

### Demo程序简介

[上一篇](/posts/blog-opengl-transformations-1.html)已经给出了Demo程序的地址，为了明确，这里把地址再贴一遍。本文中出现的代码，都来自于下面这个文件：

* <https://github.com/tielei/OpenGLESTransformationsDemo/blob/master/app/src/main/java/com/zhangtielei/demos/opengles/transformations/MainActivity.java>{:target="_blank"}

首先，vertex shader中跟坐标变换有关的是下面这一行代码：

```java
	gl_Position = projection * view * model * vec4(position.xyz, 1);
```

它表示，对一个顶点坐标依次进行model、view、projection三种变换。这三种变换，分别是通过左乘一个矩阵来完成的。在上面这行代码中，看起来三个变换的顺序跟我们期望的相反了，但这正是矩阵左乘造成的结果。

代码中的`vec4(position.xyz, 1)`表示顶点在本地坐标系中的坐标（用一个四维的齐次坐标来表达，我们下面会详细介绍）。它左边乘上model矩阵，就得到了该顶点在世界坐标系中的坐标。[上一篇](/posts/blog-opengl-transformations-1.html)我们已经讲过，这个model变换可能包含了缩放(scaling)、旋转(rotation)、平移(translation)这三种变换。然后，世界坐标系中的坐标再左乘一个view矩阵，就变换到了相机坐标系。最后，再左乘projection矩阵，就完成了投影变换。

那么这行代码中的model、view、projection这三个矩阵，它们的值是什么呢？我们看一下在Demo程序中它们的值是怎样分别计算。以第2个立方体为例，计算model矩阵的代码如下：

```java
	Matrix.setIdentityM(modelMatrix2, 0);
	Matrix.translateM(modelMatrix2, 0, 0.5f, 1.0f, -1.5f);
	Matrix.rotateM(modelMatrix2, 0, angle, 0.0f, 1.0f, 0.0f);
	Matrix.scaleM(modelMatrix2, 0, 1.5f, 1.5f, 1.5f);
```

这段代码中的`modelMatrix2`就是要计算的model矩阵，它是一个4x4的矩阵，存储在一个长度为16的float数组里(`float[16]`)。为什么不是3x3的矩阵呢？这跟齐次坐标有关，我们后面再说，现在先不管它。我们调用了Android SDK中的`Matrix`工具类的方法对其进行了赋值。`setIdentityM`表示设置一个初始的单位矩阵，而`translateM`, `rotateM`和`scaleM`表示在这个初始的单位矩阵基础上依次对矩阵进行调整，分别执行平移、旋转、缩放操作。需要注意的是，这里的代码调用顺序虽然是先平移，然后旋转，最后再进行缩放，但这些操作的含义却需要反过来解释，也就是说先进行了一个缩放操作，然后进行了旋转，最后才执行了平移操作。这其中的原因仍然与矩阵左乘的含义有关，相关细节我们会在本文最后一部分再详细解释。现在我们暂且记住这些操作的解释顺序，那么上面这段代码的精确含义就是：

1. **缩放**：先在x, y, z三个坐标轴上都放大1.5倍；
2. **旋转**：再绕着向量[0.0, 1.0, 0.0]<sup>T</sup>(也就是y轴)旋转角度`angle`；
3. **平移**：沿x轴正向平移0.5个单位，沿y轴正向平移1.0个单位，沿z轴负向平移1.5个单位。

如果你已经运行了Demo程序，那么根据上面这段描述，你就会看到这个立方体正是屏幕最上面的那个最大的立方体。它沿着一个轴在不停地旋转。之所以会旋转，是因为上面第2步中旋转的角度`angle`是个动态的值，它的值每一帧都在变化，所以看起来在不停地旋转。

[<img src="/assets/photos_opengl_trans/cube_drawing.png" style="width:300px" alt="例子程序输出截图" />](/assets/photos_opengl_trans/cube_drawing.png)

看到这里，估计有些同学禁不住会想，在上面的描述中，y轴是不是就是指向屏幕的上方？z轴是不是就是垂直于屏幕？不是的。当我们提到坐标以及坐标轴的时候，我们首先必须搞清我们当前在谈论的到底是哪个坐标系。在整个计算过程中，我们经常会在不同的坐标系之间切换。根据[上一篇](/posts/blog-opengl-transformations-1.html)的介绍，我们当前正在谈论的model变换是从本地坐标系变换到世界坐标系，因此，这里的x, y, z三个坐标轴指的是世界坐标系。而世界坐标系与屏幕的角度和位置没有直接关系，这取决于后面的view变换（从哪个角度去观察）。

接下来，我们再看一下在Demo程序中view矩阵是怎样计算的。

```java
	 Matrix.setLookAtM(viewMatrix, 0, 3.0f, 3.0f, 10.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
```

这行代码中的`viewMatrix`就是要计算的view矩阵，它也是一个4x4的矩阵。我们仍然是调用了`Matrix`工具类的方法对其进行了赋值。它表达的意思是：我们把眼睛（或者说相机）放在世界坐标系的(3.0, 3.0, 10.0)这个点，然后观察的方向正对着点(0.0, 0.0, 0.0)，即世界坐标系的原点。同时我们还需要指定一个「头朝上」的方向，这在代码里设置的是向量(0.0, 1.0, 0.0)指向「上」的方向。

最后看一下projection矩阵的计算：

```java
 	Matrix.perspectiveM(projectionMatrix, 0, 45.0f, width / (float) height, 0.1f, 100.0f);
```

这行代码中的`projectionMatrix`就是要计算的projection矩阵，它同样也是一个4x4的矩阵。'Matrix.perspectiveM'对这个矩阵进行了赋值，这个调用需要的几个输入参数如下：

* 观察视角为45.0度。这个值通常被称为field of view，简称fov。它的含义已在下图中标出。

[<img src="/assets/photos_opengl_trans/clip_space_fov.png" style="width:500px" alt="投影变换fov展示图" />](/assets/photos_opengl_trans/clip_space_fov.png)

* 第二个参数为宽高比，指的是近平面(N)的宽高比。
* 第三和第四个参数分别表示近平面(N)和远平面(F)与相机位置的距离。

现在，与model、view、projection三个矩阵的计算有关的代码我们都看到了，已经粗略知道了整个计算的流程。下一节我们就定量地分析一下其中某些矩阵的计算过程。

### 缩放和平移矩阵的推导

#### 关于线性代数理论基础的说明

在前面（包括[上一篇](/posts/blog-opengl-transformations-1.html)）我们提到坐标变换的时候，一直在说对顶点进行变换，但是，我们知道，在线性代数中我们研究的概念都是基于向量的，并没有点的概念。向量的原始概念是一个由*n*个数组成的*n*元数组。当把向量对应到几何空间中的时候，我们才有了点的概念，以及点和向量的关系。

[<img src="/assets/photos_opengl_trans/vector_and_point.png" style="width:300px" alt="向量和点概念图" />](/assets/photos_opengl_trans/vector_and_point.png)

如上图，我们建立了一个直角坐标系，![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP}}) 就是一个向量，它表示一个有大小和方向的量。把它表示在坐标系里的时候，起点在原点**O**，终点指向点**P**。这个向量的坐标和点**P**的坐标一样，都可以记为(1,2)。也就是说，任意一个点和一个由原点指向该点的向量是可以一一对应的，这样我们这里讲的OpenGL ES里对于顶点(vertex)的坐标变换，就可以和线性代数里讲的对于向量的线性变换以及坐标变换的知识，对应起来了。

在后面的描述中，为了方便，我们有时候会说对向量进行变换，有时候会说对点(或顶点)进行变换，这两种说法是等价的，因为一个点和一个起点在原点且终点在这个点的向量一一对应。

在直角坐标系中表达的向量还有一个性质，就是向量与起点位置无关，也就是说，一个向量向任意方向平移之后不变。比如，在上图中，![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{AQ}}) 是由向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP}})  平移之后得到的向量，平移前后它们的大小和方向都一样，所以它们表示相同的向量。所以，平移后的向量![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{AQ}}) 仍然以坐标(1,2)来表达。

既然向量平移后坐标不变，那么我们要对顶点进行平移变换，就不能直接通过对一个向量的平移来得到。实际上，我们会用到两个向量加法（下一节我们马上会看到）。

在线性代数中，我们有线性变换的概念，它的理论基础非常丰富和完善，但是我们要讨论的OpenGL ES里的各个变换过程，却不能完全被线性变换所囊括。比如，缩放和旋转可以用线性变换来表达，但平移不能。我们后面要讨论的view变换和投影变换，也不属于线性变换。实际上，它们属于仿射变换([Affine Transformation](https://en.wikipedia.org/wiki/Affine_transformation){:target="_blank"})的范畴。我们先不过早地进入这些抽象概念的讨论，而是对于每个变换具体地去讨论它们的推导过程。也许到最后，当我们回过头来再看这些抽象概念的时候，会看得更加清楚。

#### 平移矩阵的推导过程

首先，我们先来考虑顶点的平移(translation)。这可以通过向量加法来完成。见下图。

[<img src="/assets/photos_opengl_trans/vector_addition.png" style="width:300px" alt="向量加法展示图" />](/assets/photos_opengl_trans/vector_addition.png)

图中**A**点平移到**B**点，相当于做一个向量加法：

![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OA}} + \boldsymbol{\overrightarrow{AB}} = \boldsymbol{\overrightarrow{OC}})

我们看到，在直角坐标系中，向量加法满足三角形法则。其中向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{AB}}) 代表了平移的大小和方向，称为平移向量(translation vector)。为了更清楚地读出这个平移向量的坐标，我们把它平移到原点处，它和向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OA'}}) 相等，能看出它的坐标是(0.5,1)。向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OA}}) 加上这样的一个平移向量，相当于把点**A**沿x轴平移0.5个单位，并沿y轴平移1个单位，这样就平移到了点**B**的位置。

前面图中是2维向量的例子，现在我们扩展到3维，将平移变换用向量坐标来表示，如下：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
x \\ 
y \\
z
\end{bmatrix}
+
\begin{bmatrix} 
T_x \\
T_y \\
T_z 
\end{bmatrix}
=
\begin{bmatrix} 
x + T_x \\ 
y + T_y \\
z + T_z
\end{bmatrix})

上式中的

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
T_x \\
T_y \\
T_z 
\end{bmatrix})

就是前面提到的平移向量(translation vector)的值。

在线性代数中，一个变换通常使用矩阵的乘法来表达。况且OpenGL ES使用GPU来进行运算，而GPU对于矩阵乘法有着非常高效的算法。我们也希望这里的平移变换能用矩阵乘法（具体说是左乘）来表达。我们设想一个3x3的矩阵**A**，让它乘上顶点的3维坐标：

![](http://latex.codecogs.com/png.latex?\boldsymbol{A}
\begin{bmatrix} 
x \\
y \\
z 
\end{bmatrix}
=
\begin{bmatrix} 
a_{11} & a_{12} & a_{13} \\ 
a_{21} & a_{22} & a_{23} \\ 
a_{31} & a_{32} & a_{33} \\ 
\end{bmatrix}
\begin{bmatrix} 
x \\
y \\
z 
\end{bmatrix}
=
\begin{bmatrix} 
a_{11}x + a_{12}y + a_{13}z \\ 
a_{21}x + a_{22}y + a_{23}z \\ 
a_{31}x + a_{32}y + a_{33}z \\ 
\end{bmatrix}
)

我们发现，无论矩阵**A**的各个元素取什么样的值，我们只能得到x,y,z的线性组合，而怎么样也得不到类似前面向量加法的结果形式（x,y,z分别加上一个常数）。为了解决这个问题，我们将3维的顶点坐标换成4维的齐次坐标。所谓齐次坐标，就是在3维坐标的基础上，加上第4个维度，并把它的值设成1。也就是说，3维坐标

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
x \\ 
y \\
z
\end{bmatrix})

变成齐次坐标就是：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
x \\ 
y \\
z \\
1
\end{bmatrix})

当然，齐次坐标的第4个元素，也可以不是1，不过这种情况我们暂时用不到，等我们讨论到投影变换和perspective division的时候再仔细探讨这种情况。现在我们暂且简单的认为，齐次坐标就是多了第4个维度，并且它是一个固定的1。实际上，在OpenGL ES中，我们总是以4维的齐次坐标来表示顶点坐标。

这样，一个4维的顶点坐标经过左乘一个矩阵，得到的结果也是一个4维的顶点坐标。这个矩阵需要是4X4的。根据矩阵乘法的定义，现在我们很容易拼出一个能表示平移的矩阵来：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
1 & 0 & 0 & T_x \\ 
0 & 1 & 0 & T_y \\ 
0 & 0 & 1 & T_z \\ 
0 & 0 & 0 & 1 \\ 
\end{bmatrix}
\begin{bmatrix} 
x \\
y \\
z \\
1
\end{bmatrix}
=
\begin{bmatrix} 
x + T_x \\ 
y + T_y \\
z + T_z \\
1
\end{bmatrix}
)

上式中的矩阵：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
1 & 0 & 0 & T_x \\ 
0 & 1 & 0 & T_y \\ 
0 & 0 & 1 & T_z \\ 
0 & 0 & 0 & 1 \\ 
\end{bmatrix}
)

正是我们要推导的平移矩阵。它是4x4的。我们发现，它左上角是一个3x3的单位矩阵，第4列前3个元素恰好是平移向量。

#### 缩放矩阵的推导过程

[<img src="/assets/photos_opengl_trans/vector_scale.png" style="width:300px" alt="向量缩放展示图" />](/assets/photos_opengl_trans/vector_scale.png)

上图表达了2维向量的缩放过程。向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP}}) 在x和y方向上都放大了1.5倍就得到了向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP_1}}) ，坐标从(2,1)变换成了(3,1.5)。这种缩放符合比较符合我们常识中的「放大」或「缩小」，即各个维度上都「放大」或「缩小」相同的倍数。如果在3D空间中的一个对象的各个顶点都「放大」或「缩小」相同的倍数，那么这个3D对象本身就「放大」或「缩小」了相应的倍数。

但是，OpenGL ES里的缩放变换可以表达更一般的情形，也就是各个维度上缩放不同的倍数。还是以上图2维向量为例，向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP}}) 在x方向上缩小为原来的0.5倍，在y方向上放大为原来的2倍，就得到了向量 ![](http://latex.codecogs.com/png.latex?\boldsymbol{\overrightarrow{OP_2}}) ，坐标从(2,1)变换成了(1,2)，这也是一种缩放变换。

从上面的例子可见，缩放变换就是把各个维度的坐标分别「放大」或「缩小」一个倍数。扩展到3D空间，仍然使用4维的齐次坐标，缩放操作用矩阵乘法可以写成：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
S_1 & 0 & 0 & 0 \\ 
0 & S_2 & 0 & 0 \\ 
0 & 0 & S_3 & 0 \\ 
0 & 0 & 0 & 1 \\ 
\end{bmatrix}
\begin{bmatrix} 
x \\
y \\
z \\
1
\end{bmatrix}
=
\begin{bmatrix} 
S_1x \\ 
S_2x \\
S_3x \\
1
\end{bmatrix}
)

上面这个式子意思就是，一个向量的x,y,z坐标经过缩放变换之后，分别变成了原来S<sub>1</sub>,S<sub>2</sub>,S<sub>3</sub>倍。而式子中左乘的这个4x4的矩阵，就是我们要推导的缩放矩阵：

![](http://latex.codecogs.com/png.latex?\begin{bmatrix} 
S_1 & 0 & 0 & 0 \\ 
0 & S_2 & 0 & 0 \\ 
0 & 0 & S_3 & 0 \\ 
0 & 0 & 0 & 1 \\ 
\end{bmatrix}
)

### Android中缩放和平移的实现


---

本文已经基本说明了这整个的分析思路，这个系列后面的文章仍然会遵循这一思路。等不及的读者已经可以按照类似的方法开始探索之旅了。



（完）


**其它精选文章**：

* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&amp;mid=2657261555&amp;idx=1&amp;sn=3662a2635ecf6f67185abfd697b1057c&amp;chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [分层的概念——认知的基石](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261549&idx=1&sn=350d445acf339ce19e7aab1ff19d92d0&chksm=84479e34b3301722aea0aaaa6f74656dd3e9509d70bf5719fb3992d744312bdd1484fc0c1852#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)
* [程序员的武林秘籍](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261552&idx=1&sn=dca554ca23c19394b1e0863bf08b5d49&chksm=84479e29b330173fc24e9c32e20ccd628ddfc6f9c71546dc31f4ebee49fca1c1bc4cc19d31c7#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [技术攻关：从零到精通](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261530&idx=1&sn=6e2e80a0895325861541c2b4266ae374&chksm=84479e03b3301715c53f0eebff06f6eca7d4a4089a635a2628e31480a5ca9e328403992f435b#rd)
* [那些让人睡不着觉的bug](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261538&idx=1&sn=0e4f6bec50f450528877cb7787fdc322&chksm=84479e3bb330172d988f3f3981c4af06d6898a236ebdb9aca35f3fe15c8b89f25b1981ca9c79#rd)
* [蓄力十年，做一个成就](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261524&idx=1&sn=f41934e050c964edd71371923c89e7cc&chksm=84479e0db330171b4211c0c31d11f94ed2508a68adc8760b173e448c26ab7b99964d5038c4dd#rd)

