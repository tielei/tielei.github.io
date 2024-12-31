---
layout: post
category: "ml"
title: "LangChain的OpenAI和ChatOpenAI，到底应该调用哪个？"
date: 2024-12-28 00:00:00 +0800
published: true
---

> 浮言易逝，唯有文字长存。  

*今天来聊一个非常具体的技术问题。*

对于工程师来说，当我们使用LangChain来连接一个LLM推理服务时，多多少少会碰到一个疑问：到底应该调用`OpenAI`还是`ChatOpenAI`？我发现，每次解释这个问题时，都会费很多唇舌，所以干脆写下来供更多人参考。这背后其实涉及到两个关键问题：
* completions 和 chat completions 两个接口的区别。
* LLM推理时用到的chat template。

<!--more-->

### completions 和 chat completions

通过LangChain来调用LLM的时候，通常会引用下面这两个类：

```python
from langchain_openai import OpenAI
from langchain_openai import ChatOpenAI
```

从这两个类的名字就不难猜出，它们是用来调用OpenAI提供的LLM接口的。具体来说，是这两个接口：
* `OpenAI`用来调用 /v1/completions 接口。
* `ChatOpenAI`用来调用 /v1/chat/completions 接口。

不过呢，由于OpenAI的影响力实在太大，很多其他闭源和开源的LLM，在提供推理服务的API时，也都不约而同地遵循了OpenAI的接口形式。这两个接口成了事实性的标准。

这两个接口的区别是什么呢？
* /v1/completions 接口提供的是「续写」能力，也就是最基础的predict next token的能力。你提供一段prompt，它返回一段续写的文本。接口的输入和输出，都是文本。
* /v1/chat/completions 接口提供的是对话能力。接口的输入是一个message list，输出是一个message。

### Base Model 和 Instruct Model

一般来说，上一节提到的这两个接口，分别对应两类LLM模型：
* **Base Model**: 仅经过预训练的基础模型，所以也称为Pretrained Model。它只能对输入的prompt进行续写。这一类模型在推理时只能提供 /v1/completions 接口。
* **Instruct Model**: 在预训练之后经过进一步指令微调过的模型。只有这一类模型在推理时才能提供 /v1/chat/completions 接口。

以Llama 3模型系列为例：

[<img src="/assets/images_chat_template/llama3_model_list.jpg" style="width:800px" alt="Llama 3 模型列表" />](/assets/images_chat_template/llama3_model_list.jpg)

在以上这个表格中，以“-Instruct”结尾命名的模型，就属于Instruct Model；反之就是Base Model。

OpenAI在早期推出API服务的时候，/v1/completions 和 /v1/chat/completions 这两个接口是都提供的。但随着时间的推移和技术的迭代，大部分AI应用场景都能用指令对话的形式来支持，所以后来OpenAI也就不再为最新的模型提供 /v1/completions 接口了。现在如果访问OpenAI关于 /v1/completions 接口的API reference文档页面[1]，你会发现这个接口已经被标记为“Legacy”了。

结合前一节所讨论的，我们现在容易得出结论，如果我们想调用OpenAI的GPT模型，那么应该选择使用LangChain的`ChatOpenAI`这个类。

但是，如果我们使用开源推理框架（如vLLM[2]）来为了开源模型在本地架设推理服务，那么通常来说，这个推理服务可能会同时支持/v1/completions 和 /v1/chat/completions 这两个接口。当我们使用LangChain进行调用的时候：
* 如果加载的是一个Base Model，那么只有 /v1/completions 接口可用，/v1/chat/completions 接口是不可用的（或者说，调用它没有意义）。我们只能使用LangChain的`OpenAI`这个类进行调用。
* 如果加载的是一个Instruct Model，那么理论上来说，我们应该调用 /v1/chat/completions 接口进行推理。也就是使用LangChain的`ChatOpenAI`这个类来进行调用。但是，由于对话消息在经过格式化之后，最终也是表达成一个文本串的，所以其实 /v1/completions 也是可用的，这时候就可以调用LangChain的`OpenAI`这个类。这个过程我们后面的章节再仔细展开。

### 关于chat template

根据前面的分析，我们知道了，调用 /v1/chat/completions 接口，我们需要使用LangChain的`ChatOpenAI`这个类，并且传入一个message list。下面是一段示例代码：

```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate

llm = ChatOpenAI(
  openai_api_key="EMPTY",
  openai_api_base="http://127.0.0.1:8000/v1",
  model_name="llama3.2-1B-instruct"
)

prompt = ChatPromptTemplate.from_messages([
    ("system", "Your are a helpful assistant."),
    ("user", "Hello, how are you?"),
    ("assistant", "I'm doing well, thank you for asking."),
    ("user", "Can you tell me a joke?")
  ]
)

chain = prompt | llm

reponse = chain.invoke({})
```

在这段代码中，我们看到，传入给LLM的是一个有结构的对话历史列表。但是，不管是Base Model还是Instruct Model，模型最终接受的输入，应该是一段free text（再转成token）。那么问题来了，这个有结构的对话历史列表，是如何转成free text的呢？显然，这里需要一个模板（template），这就是所谓的chat template[3]。

对于前面示例代码中的 llama3.2-1B-instruct 模型，它所对应的chat template是下面这个样子的：
[<img src="/assets/images_chat_template/llama3_chat_template.jpg" style="width:800px" alt="Llama 3 chat template" />](/assets/images_chat_template/llama3_chat_template.jpg)

这是一个遵循Jinja格式的模版[4]。模板表达了各种message（包括system message，user message，assistant message以及其它类型的message）的渲染方式。

基于这个chat template，前面示例代码中的对话历史内容，最终输入到LLM时会转化成如下的free text（也就是prompt）：

```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

Cutting Knowledge Date: December 2023
Today Date: 28 Dec 2024

Your are a helpful assistant.<|eot_id|><|start_header_id|>user<|end_header_id|>

Hello, how are you?<|eot_id|><|start_header_id|>assistant<|end_header_id|>

I'm doing well, thank you for asking.<|eot_id|><|start_header_id|>user<|end_header_id|>

Can you tell me a joke?<|eot_id|><|start_header_id|>assistant<|end_header_id|>


```

那么，这个chat template是从哪里来的呢？对于vLLM来说，它启动的时候，有两种方式可以获取到chat template：
* 一种方式是从模型文件夹中加载。具体地说，chat template的内容存在于tokenizer_config.json文件中。
* 另一种方式是vLLM通过启动参数*\-\-chat-template*来指定一个chat template模板文件。

我们顺便看一个tokenizer_config.json文件的具体例子。还是以前面示例代码中调用的 llama3.2-1B-instruct 模型为例，它的chat template模板内容就存在tokenizer_config.json文件中的chat_template字段中，如下：

[<img src="/assets/images_chat_template/llama3_tokenizer_config.json.jpg" style="width:800px" alt="Llama 3 tokenizer_config.json" />](/assets/images_chat_template/llama3_tokenizer_config.json.jpg)

这里多说一句：我们需要注意的是，**tokenizer_config.json文件中并不一定包含chat_template字段**。具体有没有这个字段，取决于模型文件的创建过程。对于Llama 3模型来说，我们从Meta官方[5]申请并下载到模型文件之后，一般情况下，需要使用Hugging Face的Transformers框架中提供的一个工具[6]，将模型转换成hf的通用格式。这样，vLLM以及其它开源生态中的框架或工具才能方便地加载它。

以 llama3.2-1B-instruct 模型为例，这个模型格式的转换过程，需要执行以下命令来调用Transformers的这个工具：

```shell
python src/transformers/models/llama/convert_llama_weights_to_hf.py --input_dir <llama3.2-1B-instruct model source folder> --model_size 1B --llama_version 3.2 --output_dir <llama3.2-1B-instruct model output folder> --instruct
```

在以上命令中，如果带着*\-\-instruct*参数，那么转换成的模型配置文件tokenizer_config.json中就包含chat_template字段；否则就不包含chat_template字段。

注意，以上命令执行之前，需要先执行*huggingface-cli login*命令登录Hugging Face，并确保在"meta-llama/Llama-3.2-1B-Instruct"的Hugging Face模型主页上提交了访问申请并获批，只有这样这个命令才能执行成功。

### 其他需要注意的问题

由上一节可知，假如tokenizer_config.json文件中没有包含chat_template字段，并且vLLM在启动时也没有指定*\-\-chat-template*，那么，vLLM会以未指定chat template模板的方式启动起来。

这个时候，如果还是像本文前面的代码那样调用LangChain的`ChatOpenAI`，就会**出现意想不到的结果。一定要注意！**具体会得到怎样的结果，取决于你使用的vLLM运行环境中Transformers的版本：
* 如果Transformers的版本小于4.44，vLLM会自动使用一个默认的chat template。这时候从调用结果上很可能看不出什么大问题，但实际上模型**回答的准确度已经大打折扣，这个错误非常不易察觉**。
* 如果Transformers的版本大于等于4.44，vLLM会抛一个异常，如下：

```shell
openai.BadRequestError: Error code: 400 - {'object': 'error', 'message': 'As of transformers v4.44, default chat template is no longer allowed, so you must provide a chat template if the tokenizer does not define one.', 'type': 'BadRequestError', 'param': None, 'code': 400}
```

显然，高版本的Transformers和vLLM对于这个情况的处理，更合理一些。通过明显的报错避免了不易察觉的错误。

如前所述，由于对话消息在经过格式化之后，最终也是表达成一个文本串的，所以也可以调用LangChain的`OpenAI`这个类来完成。这时候其实背后是在调用 /v1/completions 这个接口。相当于client端在调用`OpenAI`之前，先把prompt按照需要的对话格式拼好。下面的代码，可以实现跟前面调用`ChatOpenAI`的代码同样的效果：

```python
from langchain_openai import OpenAI
from langchain_core.prompts import PromptTemplate
from datetime import datetime

llm = OpenAI(
  openai_api_key="EMPTY",
  openai_api_base="http://127.0.0.1:8000/v1",
  model_name="llama3.2-1B-instruct"
)

prompt_text = """<|begin_of_text|><|start_header_id|>system<|end_header_id|>

Cutting Knowledge Date: December 2023
Today Date: {today_date}

Your are a helpful assistant.<|eot_id|><|start_header_id|>user<|end_header_id|>

Hello, how are you?<|eot_id|><|start_header_id|>assistant<|end_header_id|>

I'm doing well, thank you for asking.<|eot_id|><|start_header_id|>user<|end_header_id|>

Can you tell me a joke?<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""

prompt = PromptTemplate.from_template(prompt_text)

chain = prompt | llm

reponse = chain.invoke({"today_date":datetime.now().strftime('%d %b %Y')})
```

### 小结

现在我们总结一下本文开头提出的问题：
* 对于Base Model的推理服务，只能使用LangChain的`OpenAI`这个类来调用。
* 对于Instruct Model的推理服务：
  * 如果vLLM启动时加载到了正确的chat template（或从模型目录中或从启动参数中），那么：
    * 推荐使用LangChain的`ChatOpenAI`这个类来调用。**这是最推荐的一种方式**。
    * 也可以使用LangChain的`OpenAI`这个类来调用。但要求在调用之前先把prompt按照所需的对话格式拼好（chat template实际上没有用到）。
  * 如果vLLM启动时没有加载到正确的chat template，那么就只能使用LangChain的`OpenAI`这个类来调用（要求在调用之前先把prompt按照所需的对话格式拼好）。

（正文完）

##### 参考文献：
* [1] [Create completion](https://platform.openai.com/docs/api-reference/completions/create).
* [2] [vLLM GitHub主页](https://github.com/vllm-project/vllm).
* [3] [Chat Templates](https://huggingface.co/docs/transformers/main/en/chat_templating).
* [4] [Jinja GitHub主页](https://github.com/pallets/jinja/).
* [5] [Request Access to Llama Models](https://www.llama.com/llama-downloads).
* [6] [convert_llama_weights_to_hf.py](https://github.com/huggingface/transformers/blob/main/src/transformers/models/llama/convert_llama_weights_to_hf.py).


**其它精选文章**：

* [技术变迁中的变与不变：如何更快地生成token？](https://mp.weixin.qq.com/s/BPnX0zOJr8PLAxlvKQBsxw)
* [DSPy下篇：兼论o1、Inference-time Compute和Reasoning](https://mp.weixin.qq.com/s/hh2BQ9dCs1HsqiMYKf9NeQ)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [用统计学的观点看世界：从找不到东西说起](https://mp.weixin.qq.com/s/W6hSnQPiZD1tKAou3YgDQQ)
* [从GraphRAG看信息的重新组织](https://mp.weixin.qq.com/s/lCjSlmuseG_3nQ9PiWfXnQ)
* [企业AI智能体、数字化与行业分工](https://mp.weixin.qq.com/s/Uglj-w1nfe-ZmPGMGeZVfA)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
