# Abstract

Chain-of-thought (CoT) decoding enables language models to improve reasoning performance at the cost of high generation latency in decoding. Recent proposals have explored variants of *contemplation tokens*, a term we introduce that refers to special tokens used during inference to allow for extra computation. Prior work has considered fixed-length sequences drawn from a *discrete* set of embeddings as contemplation tokens. Here we propose Compressed Chain-of-Thought (CCoT), a framework to generate *contentful* and *continuous* contemplation tokens of variable sequence length. The generated contemplation tokens are compressed representations of explicit reasoning chains, and our method can be applied to off-the-shelf decoder language models. Through experiments, we illustrate how CCoT enables additional reasoning over dense contentful representations to achieve corresponding improvements in accuracy. Moreover, the reasoning improvements can be adaptively modified on demand by controlling the number of contemplation tokens generated.

# Introduction

Chain-of-Thought (CoT) refers to the Large Language Model (LLM) technique in which the model simulates the process of thinking out loud by decomposing a complex question into parts and sequentially reasoning through each step. This behavior can be induced by finetuning on a dataset or human feedback [liu2023chainhindsightalignslanguage; puerto2024finetuningdivergentchainsthought], demonstrating through ICL [wei2023chainofthoughtpromptingelicitsreasoning], or by providing tuned model instructions [kojima2023largelanguagemodelszeroshot]. While CoT improves the reasoning capabilities of LLMs on a variety of tasks, the improvements come at the cost of a high generation latency. For instance, GPT-4o takes 21.37 seconds to generate a response to the question shown in Figure 1 with CoT prompting, whereas it can answer the same question without CoT prompting in 2.81 seconds, achieving the same answer with an almost 10x speedup.

Past work has utilized what we term *contemplation tokens* as an alternative to explicit CoT reasoning traces [pfau2024letsthinkdotdot; goyal2024thinkspeaktraininglanguage]. These are additional tokens used to introduce online memory, allowing for additional computations during inference. Instead of generating a reasoning chain entirely of explicit language tokens, the model conditions on a shorter sequence of contemplation tokens (Section 2). Contemplation tokens can either be *contentful*, grounded in semantically meaningful text, or *noncontentful*. There are many lines of prior work involving *noncontentful* contemplation tokens drawn from a set of *discrete* tokens; this paper introduces *contentful* contemplation tokens that represent reasoning chains performed in *continuous* space.

Our framework, called Compressed Chain of Thought (CCoT), generates contemplation tokens which are compressed representations of language-based reasoning chains. These contemplation tokens are trained through teacher forcing with respect to the gold hidden states corresponding to full reasoning traces. Our framework can be adapted to pretrained LLMs through LoRA finetuning. Moreover, the variable compression ratio during training allows for need-based adjustments to the performance-efficiency tradeoff by controlling the number of tokens generated during inference.

[IMAGE: Two approaches to step by step reasoning. Chain of Thought (CoT) prompting reasons via discrete language tokens, leading to long sequences that incur significant generation costs. In contrast Compressed Chain of Thought (CCoT) elicits reasoning with a short sequence of continuous embeddings, allowing for much greater throughput.]

The contributions of this paper are as follows:

1.  We finetune pretrained decoder-only LLMs with our new CCoT framework and empirically evaluate their performance and throughput on GSM8K;

2.  We establish our framework in context of related work in filler tokens and CoT distillation in terms of performance and efficiency;

3.  We extend theoretical results and demonstrate the computational capacity of CCoT contemplations tokens.

# Related Work

#### Distillation of Knowledge Chains

There has been work in distilling the computations done explicitly when decoding the reasoning chains into computation of the hidden states of the answer [deng2023implicitchainthoughtreasoning; deng2024explicitcotimplicitcot]. Contemporaneous work distills reasoning paths into continuous latent tokens [hao2024traininglargelanguagemodels]. Our method differs in that the contemplation tokens we generate are grounded in text rather than only used as a signal to decode from. This is a critical distinction: our grounding offers the future potential for decoding the reasoning chain from the compressed representations, allowing for post-hoc human inspection of the LLM's reasoning. Moreover, our method successfully adapts a much larger model (7B compared to 1.5B) using a fraction of data (approximately 9000 instances in GSM8K compared to approximately 400000 instances in an unreleased augmented GSM8K). This suggests that our method can scale better to larger models and is more data efficient.

#### Filler (Pause) Tokens

Many previous methods have considered decoding *contemplation tokens* to provide an LLM with more compute during inference time. These tokens have gone by many names, such as pause tokens [goyal2024thinkspeaktraininglanguage], memory tokens [burtsev2021memorytransformer], filler tokens [pfau2024letsthinkdotdot], and thinking tokens [herel2024thinkingtokenslanguagemodeling]. These works mainly focus on *noncontentful* contemplation tokens, whose main advantage is their ability to be decoded in parallel, providing the model with a greater computational width without the need to autoregressively decode.

They have been shown to increase the theoretical computational ability of Transformer LLMs [pfau2024letsthinkdotdot], but cannot simply be naively applied to induce reasoning gains [lanham2023measuringfaithfulnesschainofthoughtreasoning]. However, through careful pretraining and finetuning, pause tokens have been shown to improve reasoning in both RNNs [herel2024thinkingtokenslanguagemodeling] and Transformers [goyal2024thinkspeaktraininglanguage]. In contrast, the contemplation tokens generated by CCoT are contentful as they are compressed representations of reasoning chains. Moreover, they are decoded autoregressively resulting in a greater computational depth as well as width.

#### Contextual Compression

Transformer LLMs are the de facto standard architecture for modern NLP applications. However, due to the quadratic complexity of its self-attention mechanism, these LLMs are inefficient in tasks with long contexts. Many techniques have been proposed to alleviate this issue, including memory slots [ge2024incontextautoencodercontextcompression], dynamic compression into nuggets [qin2024dododynamiccontextualcompression], and low level cache encoding [cachegen]. While most techniques rely on access to the intermediate hidden states of LLMs, there has also been work done in the context of API-only LLMs [jiang2023llmlinguacompressingpromptsaccelerated]. Overall, most of the work in contextual compression deals with efficient compression of known context in order to improve generation latency. The compressed context can then be used in downstream tasks such as retrieval augmented generation or summarization.

The area of context compression is orthogonal to *contemplation tokens*. The memory slots of [ge2024incontextautoencodercontextcompression] and the nuggets from [qin2024dododynamiccontextualcompression] encode contentful representations of *known* context, but they are only attended to and never generated during inference. While our work focuses on contentful representations of text, there are two crucial differences: our compressed representations are autoregressively *decoded* during inference and they encode content that is a priori *unknown*.

**Table 1: Comparison of contemplation token methods**

| Method | Contentful | Format | Inference | Notes |
|--------|------------|--------|-----------|-------|
| Chain of Thought [wei2023chainofthoughtpromptingelicitsreasoning] | Yes | Discrete | Variable-length; Autoregressively | Best performing method across reasoning tasks; requires no finetuning; inefficient due to unconstrained sequence length. |
| Filler Tokens [pfau2024letsthinkdotdot] | No | Discrete | Fixed-length; In parallel | Explicit example of problems only solvable with contemplation tokens. |
| Pause Tokens [goyal2024thinkspeaktraininglanguage] | No | Discrete | Fixed-length; In parallel | Best gains seen when contemplation tokens are added during pretraining stage. |
| COCONUT [hao2024traininglargelanguagemodels] | Yes | Continuous | Fixed-length; Autoregressively | Trains contemplation tokens by inserting them after removing reasoning steps. |
| CCoT (Ours) | Yes | Continuous | Variable-length; Autoregressively | Trains contemplation tokens to approximate compressed reasoning chains. |

#### Chain of Thought

Chain-of-thought [wei2023chainofthoughtpromptingelicitsreasoning] was introduced as a prompting method leveraging in-context learning (ICL) using hand crafted demonstrations. Kojima et al. showed similar behavior could be elicited in a zero-shot context by instructing a model to "think step-by-step." There have been a variety of innovations to CoT, improving on its efficiency and performance.

In terms of efficiency, novel techniques include getting an LLM to generate steps in parallel from a generated template [ning2024skeletonofthoughtpromptingllmsefficient] and generating reasoning chains in parallel using Jacobi decoding [kou2024cllmsconsistencylargelanguage; zhang2024fastchainofthoughtglancefuture]. In terms of performance, techniques include generating multiple reasoning paths [yao2023treethoughtsdeliberateproblem], and finetuning on human feedback on generated chains [liu2023chainhindsightalignslanguage; puerto2024finetuningdivergentchainsthought]. Our method differs from prior work in improving the efficiency of CoT as it is not prompt-based and does not rely on Jacobi decoding.

# Contemplation Tokens

## Preliminaries and Notation

We first give a brief overview of a causal decoder-only language model, equipped with standard Transformer blocks [vaswani2023attentionneed]. Let ```latex $V$``` be the vocabulary and ```latex $w_{1:n}$``` be an input sequence, ```latex $w_i \in V$```. Let ```latex $d$``` be the hidden dimension, ```latex $L$``` be the number of layers, and ```latex $\theta$``` be the parameters of the model. The sequence is first passed through an embedding layer, resulting in a vector ```latex $w^0_{1:n}$``` where each ```latex $w^0_i \in \mathbb{R}^d$```. The entire vector ```latex $w^0_{1:n} \in \mathbb{R}^{n \times d}$``` is then passed through a series of Transformer blocks, ```latex $T^i: \mathbb{R}^{n\times d} \to \mathbb{R}^{n\times d}$```. We denote the output of each ```latex $T^i$``` as the *hidden states*. The output of the final Transformer block, ```latex $w_{1:n}^{L} \in \mathbb{R}^{n \times d}$```, is then passed through the language model head to generate a distribution ```latex $p_{1:n}$```, ```latex $p_i \in \mathbb{R}^{|V|}$```, from which the next token is sampled.

```latex
$$\begin{align*}
    w_{1:n}^0 &= \textsc{embed}_\theta(w_{1:n}) & \triangleright\textit{embedding layer}\\
    w_{1:n}^{\ell} &= \textsc{attn}_\theta^{\ell-1}(w_{1:n}^{\ell-1}) &\triangleright\textit{ transformer blocks}\\
    p_{1:n} &= \textsc{head}_\theta(w_{1:n}^{\scriptstyle L}) &\triangleright\textit{ pass through lm head}\\
    p(w_{n+1} &\mid w_{1:n}) \sim p_n &\triangleright\textit{ sample next token}
\end{align*}$$
```

Notation-wise, any lowercase letter will refer to a *token*, lying in ```latex $V$```. Any lowercase letter with superscripts will refer to the hidden state after passing through the corresponding layer, lying in ```latex $\mathbb{R}^{d}$```. Any subscripts refers to a sequence. We will often omit superscripts and instead refer to embeddings with bars (```latex $\bar{\textrm{ }}$```) and the entire hidden state with hats (```latex $\hat{\textrm{ }}$```). Under this notation, we instead have ```latex $\textsc{embed}(w_{1:n}) = \bar{w}_{1:n}$```, and with slight abuse of notation, ```latex $\textsc{attn}(\bar{w}_{1:n}) = \hat{w}_{1:n}$```.

There are also instances where hidden states of an input are computed under two different sets of weights. Suppose we have two sequences of embeddings ```latex $\bar{w}$```, ```latex $\bar{x}$```, and we want to compute the hidden states ```latex $\hat{w}$``` under weights ```latex $\theta$``` and compute the hidden states of ```latex $\hat{x}$``` under ```latex $\psi$```, but crucially conditioned on ```latex $\hat{w}$```. In this case, we will write ```latex $\textsc{attn}_{\theta, \psi}([\bar{w} ; \bar{x}]) = [\hat{w} ; \hat{x}]$``` where semicolons indicate vector concatenation.

## Motivation

In question-answer settings, the input ```latex $w_{1:n}$``` is a query, and the answer ```latex $w_{n+1:n+o} = a_{1:o}$``` is generated autoregressively as described above. However as seen in the above description of forward passes through Transformer models, the amount of computations for each query is directly proportional to the query length ```latex $n$```. As such, we can introduce more computations to the model by attending to an a set of *contemplation tokens*, defined to be any additional tokens generated during inference used to introduce addition memory allowing for additional computations during inference. Rather than solely attending to a query ```latex $q = w_{1:n}$```, we first can generate a set of contemplation tokens ```latex $t = t_{1:m}$``` and attend to ```latex $[q; t]$``` in order to decode a better answer. We emphasize that contemplation tokens are not a novel idea, but a term introduced to unify the many names given to this concept (Section 2).

We define the contemplation tokens ```latex $t$``` to be *contentful* if either the tokens themselves are semantically contentful or the hidden states corresponding to the contemplation tokens are derived from semantically contentful tokens. We define contemplation tokens that do not fulfill either of these conditions to be *noncontentful*. An example of contentful contemplation tokens are the reasoning chains in chain of thought [wei2023chainofthoughtpromptingelicitsreasoning]; they describe the model's reasoning, fulfilling the first condition of being semantically meaningful. On the other hand, an example of noncontentful contemplation tokens are filler tokens [pfau2024letsthinkdotdot], as they are simply period characters and their hidden states are trained without any signal from semantically contentful hidden states.

Chain of thought turns out to be the only prior method involving contentful contemplation tokens. The performance gains from utilizing chain of thought are clear; however these benefits are offset by the high generation latency. Suppose the input query consists of ```latex $n$``` tokens and its corresponding reasoning chain consists of ```latex $m$``` tokens. As each of the tokens in the reasoning chain need to be autoregressively decoded, the generation of the reasoning chain incurs the cost of ```latex $m$``` extra passes through the model. Moreover when decoding the answer, the model has to attend to the additional ```latex $m$``` tokens, resulting in ```latex $O(m^2)$``` more computations when passing through each attention module. As reasoning chains are often many times longer than the query, the amount of extra computations increases dramatically. (Note: The average reasoning chain in GSM is 1.5 times longer than their corresponding query. Reasoning chains provided by GPT o1 are hundreds of times longer than their query.)

## Compressing Reasoning Chains

Prior work showed that *noncontentful* contemplation tokens only improved reasoning when the task was computationally bottlenecked [pfau2024letsthinkdotdot] or when the tokens were introduced during pretraining [goyal2024thinkspeaktraininglanguage]. We instead aim to utilize *contentful* contemplation tokens as we believe they would be more applicable to a wider set of tasks. To generate contentful contemplation tokens, we take inspiration from an empirical observation of CoT decoding.

Suppose we have an input query ```latex $w_{1:n}$``` and its corresponding reasoning chain ```latex $t_{1:m}$```. We compute the hidden states of concatenated input as ```latex $x = [\hat{w}_{1:n};\hat{t}_{1:m}]$```. Decoding an answer conditioned on the hidden states ```latex $x$``` is equivalent to prompting a language model with the query and chain of thought. Consider taking a subset of ```latex $\hat{t}_{1:m}$``` along the sequence length axis, denoted as ```latex $z_{1:k}$``` for some ```latex $k << m$```. Specifically, for each ```latex $1 \leq i \leq k$```, there exists some ```latex $1 \leq j \leq m$``` such that ```latex $z_i = \hat{t}_{j}$``` at each layer. We observe that training an adapter to decode conditioning on this shortened ```latex $[x_{1:n} ;z_{1:k}]$``` results in lossless performance on downstream tasks.

Given a query ```latex $q$```, the naive method utilizing this observation would be to autoregressively generate the reasoning chain ```latex $t$```, select some learned subset of the encoded hidden states ```latex $z$```, and train an adapter to decode from the query and subset of hidden states. While this method results in a shorter input sequence when generating the answer and thus reduces the attention computations when decoding the answer, it would still incur the linear cost in generating the reasoning chain. We instead propose learning a module to generate the compressed representations ```latex $z$``` directly. We denote this module as CCoT, short for **c**ompressed **c**hain **o**f **t**hought, as the contemplation tokens it generates are compressed representations of reasoning chains instead of the full chain.

# Approach

Assume we have a pretrained causal decoder-only language model LM, parameterized by weights ```latex $\theta$```. We wish to train two modules, CCoT and DECODE, respectively parameterized by weights ```latex $\varphi$``` and ```latex $\psi$```. At a high level given a query, ```latex $\textsc{ccot}_\varphi$``` is responsible for the generation of contemplation tokens. ```latex $\textsc{decode}_\psi$``` is responsible for decoding the answer conditioned on the initial query and contemplation tokens.

Consider a training instance consisting of a query, full reasoning chain and answer, denoted as ```latex $w_{1:n}, t_{1:m}$``` and ```latex $a_{1:o}$```, respectively. Assume some fixed compression ratio ```latex $0 < r < 1$``` and let ```latex $k = \lceil r \cdot m\rceil$```. This compression ratio controls how much the reasoning chains are compressed; ```latex $r=1$``` corresponds to finetuning on the full reasoning chain while a ```latex $r=0$``` corresponds to finetuning on just the answer. ```latex $\varphi$``` and ```latex $\psi$``` are fine-tuned successively, each initialized from ```latex $\theta$```.

## Finetuning CCoT

The goal of ```latex $\textsc{ccot}_\varphi$``` is to generate contemplation tokens. Under CCoT, these tokens are a compressed representation of a full reasoning chain, equivalent to a size ```latex $k$``` subset of the hidden states ```latex $\hat{t}_{1:m}$``` produced by ```latex $\textsc{lm}_\theta$```. Since processing all of ```latex $t$``` and then performing a subset selection still incurs the linear cost of generating all ```latex $m$``` tokens, ```latex $\textsc{ccot}_\varphi$``` is thus trained to **approximate a subset of precomputed hidden states**.

To achieve this, we first precompute the hidden states of the concatenated input. We next use a checkpoint of a scorer used to perform a similar subset selection from [qin2024dododynamiccontextualcompression] in order to perform the subset selection of the hidden states. This scorer is simply a linear layer that takes the embeddings from a predetermined layer ```latex $T$``` as input, and returns the indices of the selected subset. We discuss other methods of subset selection in Section 5.2.

```latex
$$\begin{align*}
    [\bar{w}_{1:n};\bar{t}_{1:m};\bar{a}_{1:o}] &= \textsc{embed}_\theta([w_{1:n};t_{1:m};a_{1:o}])\\
    [\hat{w}_{1:n};\hat{t}_{1:m};\hat{a}_{1:o}] &= \textsc{attn}_\theta([\bar{x}_{1:n};\bar{t}_{1:m};\bar{a}_{1:o}])\\
    I &= \textsc{scorer}(\hat{t}_{1:m}^{ \textrm{ }T})
\end{align*}$$
```

We have that ```latex $|I| = k$```, and we can index the hidden states ```latex $z_{1:k} = \hat{w}_{I}$``` to serve as the gold labels. We aim to generate ```latex $k$``` contemplation tokens ```latex $\hat{z}_{1:k}$``` conditioned on ```latex $w_{1:n}$``` under ```latex $\varphi$``` to approximate the labels, but is not immediately clear what inputs we should use to generate the contemplation tokens.

A reasonable choice is to use the embeddings of the tokens corresponding to the selected indices, ```latex $\hat{w}_I$```. This choice would make the hidden state approximation easier due to skip connections in the attention layer: ```latex $\hat{w}_I$``` are the exact inputs used to compute the hidden states in the noncompressed case. However, the selected tokens are usually punctuation tokens and articles. This choice would require predicting a random sequence of semantically empty tokens when autoregressively decoding as we pass the last layer embeddings ```latex $\hat{z}_i^{L}$``` through the language model head. Another option would be to learn a single embedding as input to generate each hidden state, but this choice removes the additional computational depth induced by autoregressive decoding.

We instead take inspiration from reasoning over continuous space and use the intermediate hidden layers of the previous contemplation token as input to the next token. Formally, the inputs to generate the contemplation tokens ```latex $\hat{z}_{1:k}$``` are the embeddings of ```latex $z_{0:k-1}^l$``` at some fixed layer ```latex $l$``` where ```latex $z_0$``` represents the hidden state of the last token of the query.

This choice is quite natural as it generalizes the naive autoregressive decoding strategy (Section 4.3). We train the parameters of ```latex $\varphi$``` layer by layer with the following loss:

```latex
$$\begin{equation*}
    \textsc{loss}_\varphi(z_i^{l}, \hat{z}^{l}_i) = \frac1{k}\sum_{i = 1}^k \frac1{\sigma^2(z_i^{l})} \textsc{mse}(z_i^{l}, \hat{z}_i^{l})
\end{equation*}$$
```

where ```latex $\sigma^2(z)$``` denotes the variance of ```latex $z$``` and MSE denotes the usual mean squared error between two vectors. We use a scaled mean squared error in order to normalize hidden states with average L1 norms. These norms differ drastically between different layers within the same model, so the scaled loss allows us to keep a consistent learning rate.

To train the ```latex $i$```th layer, we pass in the inputs described above and compute forward passes through ```latex $i$``` Transformer layers, crucially only updating the parameters corresponding to the ```latex $i$```th layer. When training subsequent layers, the parameters corresponding to the ```latex $i$```th layer are frozen. This provides a natural segmentation to the approximation task, and we found this improved the generated contemplation tokens.

## Finetuning DECODE

We assume a trained module ```latex $\textsc{ccot}_\varphi$```. Compressed reasoning chains are out of distribution for ```latex $\theta$```, so we need a separate module in order to effectively condition on the generated contemplation tokens. We train ```latex $\textsc{decode}_\psi$``` to **decode the answer from the query and contemplation tokens**.

To do this, we first encode the hidden states of the query and autoregressively generate contemplation tokens ```latex $z^*_{1:k}$```. Contrasting the training of ```latex $\textsc{ccot}_\varphi$```, we perform this generation **autoregressively** rather than using the precomputed embeddings ```latex $z_{0:k-1}^l$``` described in Section 4.1. We start by passing in ```latex $z_0^l$``` and compute the hidden states ```latex $\hat{z}_1$```. We then autoregressively take ```latex $\hat{z}_1^{l}$``` as the next input to generate ```latex $\hat{z}_2$```, until an entire sequence ```latex $\hat{z}_{1:k}$``` is generated. Then, conditioning on the query and contemplation tokens, we pass in the answer tokens ```latex $a_{1:o}$``` and compute the next-token distributions ```latex $p_{1:o}$```.

We finetune ```latex $\psi$``` with the usual cross-entropy loss given the computed distributions where the probabilities of the next token ```latex $a_i$``` are drawn from the distribution ```latex $p_{i-1}$```.

```latex
$$\begin{equation*}
    \textsc{loss}_\psi(a_{1:o}) = -\sum_{i=2}^o \log p(a_i \mid a_{1:i-1}) \sim p_{i-1}
\end{equation*}$$
```

The tokens of ```latex $a$``` are conditioned on the contemplation tokens ```latex $\hat{z}$``` generated under ```latex $\varphi$```. By unfreezing the parameters ```latex $\varphi$``` when finetuning the parameters ```latex $\psi$``` using ```latex $\textsc{loss}_\psi$```, we note that the parameters ```latex $\varphi$``` receive signal from the downstream task.

Empirically, we find that this signal is not entirely useful -- downstream performance decreased if all the parameters ```latex $\varphi$``` are unfrozen. We hypothesize that updating the parameters corresponding to earlier layers affects the autoregressive generation of the contemplation tokens. As such, we find that unfreezing the parameters corresponding to layers *after* the autoregressive layer ```latex $l$``` ends up improving performance.

```latex $k$``` will not be known during test time, so we additionally train a binary classifier ```latex $\textsc{end}_\psi$``` that takes the final layer of generated hidden states ```latex $\hat{z}_i^L$``` as input and either predicts whether another contemplation token token should be generated. We stop generating contemplation tokens after ```latex $h$``` tokens. We set ```latex $h = 200r$```, which would only prematurely terminate less than 3% of the long tailed distribution of reasoning chains.

## Inference

Assume we have a pretrained causal decoder-only language model parameterized by weights ```latex $\theta$```. Additionally, assume trained modules ```latex $\textsc{ccot}_\varphi$```, ```latex $\textsc{decode}_\psi$``` and the end predictor ```latex $\textsc{end}_\psi$```. Given a query ```latex $w$```, the inference procedure works as follows. The most crucial difference from standard CoT is that when CCoT generates contemplation tokens, it uses the ```latex $l$```th layer of the last token's hidden state as a *continuous* next input. In contrast when CoT generates contemplation tokens, it uses the final ```latex $L$```th layer to do the usual autoregressive decoding, passing to a *discrete* set of tokens. Moreover, if ```latex $m$``` is the average length of reasoning chains under ```latex $\theta$```, CCoT will generate on average only ```latex $k = \lceil r \times m \rceil$``` contemplation tokens, whereas CoT will generate on average all ```latex $m$``` tokens.

## Implementation Details

We use LoRA [hu2021loralowrankadaptationlarge] in order to finetune ```latex $\varphi$``` and ```latex $\psi$``` with ranks of 128 and 64, respectively. When generating the gold hidden states, we pass the ```latex $T=3$``` layer to perform our subset selection and the ```latex $l = 15$``` as inputs. We also take the hidden state at the ```latex $l$```th layer to do autoregressive generation of contemplation tokens when finetuning ```latex $\psi$``` and during inference. We use the decoder-only Transformer architecture of LLaMA for our experiments, taking the LLaMA2-7b-chat checkpoint [touvron2023llama2openfoundation] as our base model.

# Experiments

## Experimental Setups

We evaluate our CCoT framework on the reasoning dataset GSM8K [cobbe2021trainingverifierssolvemath]. For the reasoning chains required to train both modules, we use the chains of thought provided with the dataset. We remove all calculator annotations present in the reasoning chain, only keeping the natural language reasoning. We finetune ```latex $\varphi$``` with precomputed gold states with two compression ratios, ```latex $r = [0.05, 0.10]$```. We emphasize that the choice of ```latex $r$``` is a training time decision, ```latex $\textsc{ccot}_\varphi$``` approximates the hidden states under the fixed compression ratio ```latex $r$```.

We compare our results to two baselines of ```latex $r = [0.0, 1.0]$```. These compression ratios are the two extreme values of the compression spectrum we introduce, corresponding to the cases of no reasoning chain and full reasoning chain. We finetune the model with the usual cross entropy loss on the dataset; For ```latex $r = 0.0$```, the model directly outputs the answer without generating any contemplation tokens. For ```latex $r = 1.0$```, the model generates the explicit reasoning chain as its contemplation tokens during inference.

Additionally, we compare to PAUSE, a method derived from [goyal2024thinkspeaktraininglanguage]. We finetune the model with no reasoning chains, but for a given ratio ```latex $r$```, append ```latex $k = \lceil r \times m\rceil$``` contemplation tokens between the query and answer where ```latex $m$``` is the length of the reasoning chain. We learn the input embedding of the special token, chosen to be <pause>. These pause tokens are added to provide the model with an enhanced computational width (See Section 6.2 for further discussion). We evaluate with the same compression ratios ```latex $r = [0.05, 0.10]$``` to measure the effect of the tokens.

## Results and Discussion

We provide our main results in Table 2. Accuracy refers to the exact match accuracy obtained on the test set with no in-context examples. Decode time refers to the average time to generate an answer to a test set query, measured in seconds by wall clock time on a single Nvidia A100 GPU.

**Table 2: Accuracy and decode time on GSM8K**

| Format | 1/r | Acc. (EM) | Decode Time |
|--------|-----|-----------|-------------|
| CCoT | infinity | 0.089 | 0.33 |
| CCoT | 20x | 0.151 | 0.49 |
| CCoT | 10x | 0.179 | 0.78 |
| CCoT | 1x | 0.315 | 8.10 |
| PAUSE | 20x | 0.092 | 0.35 |
| PAUSE | 10x | 0.099 | 0.37 |

Higher accuracy indicates better performance, while lower decode time indicates better efficiency.

With a compression ratio of ```latex $r = 0.10$```, we see a 9 point improvement over the baseline with no contemplation tokens. This accuracy gain is achieved with an only 0.4 second increase in generation time. If we reduce ```latex $r$``` to 0.05, we still see a sizable 6 point improvement over the baseline, with a generation time increase of only around 0.15 seconds. In contrast, even though the contemplation tokens generated by PAUSE could be decoded faster, they were only able to nominally improve performance. We hypothesize that even though these tokens provide the model with additional computations, reasoning datasets like GSM8K require more sequential computations over parallel ones. Ultimately, our results show equipping a model with dense, contentful contemplation tokens produced by CCoT allows the model to reason better than if it had no contemplation tokens, or used a discrete set of noncontentful ones.

# Further Discussion

## Hyperparameter Choices

#### Varying r

As ```latex $r$``` controls how many contemplation tokens are generated, it makes sense that increasing ```latex $r$``` would increase both accuracy and decode time. However, we found that accuracy plateaus after a certain threshold, about ```latex $r = 0.2$```. We hypothesize that this occurs because successive contemplation tokens are autoregressively decoded using the hidden state at the ```latex $l$``` layer, which propagates an approximation to the next contemplation token generation. We suspect the noise from the approximation errors eventually outweighs the signal provided by the contemplation tokens.

#### Varying l

We find that the choice of ```latex $l$``` is important -- we were unable to learn good weights for ```latex $\varphi$``` when ```latex $l$``` was set close to either 0 or the last layer ```latex $L$```. We hypothesize that hidden states at earlier layers (small ```latex $l$```) still incorporate a lot of localized information about the token itself while hidden states at later layers (large ```latex $l$```) instead incorporate a lot of localized information about the *next* token. As such, we found that ```latex $l \approx L / 2$``` resulted in the best performance; we hypothesize that the hidden states at intermediate layers encode global information making them suitable for the autoregressive decoding scheme we use to generate contemplation tokens. We provide results with other layer choices in Appendix A.

#### Subset selection

We used a learned scorer module to perform the subset selection of the gold hidden states to be emulated by ```latex $\varphi$```. In practice, we found that simply taking ```latex $k$``` evenly spaced tokens resulted in a similar performance. However, we note that a module trained to decode from gold hidden states (in the setup described in Section 3.3) achieves lossless performance compared to decoding from the full reasoning chain, even for small values of ```latex $r$```. As such, we hypothesize that it is possible to learn a better scorer to identify a subset of hidden states that is easier to emulate; a better approximation of the gold hidden states could lead to lossless performance while only taking a fraction of the time to decode. The observed performance-efficiency tradeoff also likely occurs because it is easier to approximate sequences with less compression.

## Theoretical Considerations

We explore the enhanced computational expressivity offered by contemplation tokens and crucially identify the advantage of decoding contemplation tokens autoregressively rather than in parallel. We provide a few high level intuitions that are formalized in Appendix B.

#### Width

Suppose we have a Transformer block ATTN and an input ```latex $\bar{w}_{1:n}$```. Computing ```latex $\textsc{attn}(\bar{w}_{1:n})$``` results in ```latex $O(n)$``` parallel operations. If we pass in ```latex $m$``` additional contemplation tokens in parallel and compute ```latex $\textsc{attn}(\bar{w}_{1:n+m})$```, we now perform ```latex $O(n+m)$``` parallel operations. The extra computations matter in tasks when the number of parallel operations required is greater than the input sequence length. This can occur when answering succinctly phrased problems that require many parallel operations: "compute all pairwise sums in the following list" or "select all combinations of dependent logical statements that can be mutually true" Computing pairwise sums of an ```latex $n$``` element list requires processing ```latex $O(n^2)$``` parallel computations and computing the validity of all possible logical combinations of ```latex $n$``` facts requires processing ```latex $O(2^n)$``` ones. As ```latex $n$``` grows, introducing contemplation tokens during inference in these *width-bottlenecked* scenarios can allow models to solve additional problems.

#### Depth

Suppose we have a model consisting of ```latex $L$``` Transformer blocks, and we generate contemplation tokens autoregressively rather than in parallel. Passing in ```latex $m$``` additional contemplation tokens still results in the increased ```latex $O(n+m)$``` parallel operations, but also results in ```latex $O(mL)$``` sequential operations. These extra computations matter in tasks when the number of sequential operations required is greater than the depth of the model. This can occur in multi-hop question answering tasks or when determining the best move in sequential games such as go and chess. Introducing autoregressively decoded contemplation tokens in these *depth-bottlenecked* scenarios can allow models to solve additional problems.

To collect these observations into a formal theorem, we build from prior work that provides an analysis of the computational power of contemplation tokens decoded in parallel [goyal2024thinkspeaktraininglanguage]. We restate their theorem below:

**Theorem 1** (From [goyal2024thinkspeaktraininglanguage]). Assume that the attention module has sufficiently many parameters (```latex $K$```) that is much larger than the number of input tokens (```latex $N$```). Then there are tasks that require ```latex $M$``` independent computations, where ```latex $N < M < K$```, such that a 2-layer Transformer can implement the task if and only if it uses contemplation tokens.

Under the same assumptions, autoregressively decoded contemplation tokens can solve a broader class of problems. When the depth of a task ```latex $D$``` exceeds the number of layers in a model ```latex $L$```, the model can only represent ```latex $L$``` steps out of the required ```latex $D$``` steps. Our intuition is that contemplation tokens can "save" the intermediate steps, so autoregressively the model's representation of the ```latex $L$```th step as the input to the next token allows for the next forward pass to implement another ```latex $L$``` steps on top of the saved work. Thus, any task of depth ```latex $D$``` can be solved with an additional ```latex $D / L$``` contemplation tokens. We note that in CCoT, we only pass in the representation of the ```latex $l \approx L/2$``` step, but this doesn't detract from the asymptotic representational capacity; we simply require an additional ```latex $D / l$``` tokens instead of ```latex $D / L$```.

**Theorem 2**. Assume the conditions in Theorem 1. Then, there are tasks that involve ```latex $M$``` independent computations of a depth ```latex $D>2$``` such that a 2-layer Transformer can implement the task if and only if it autoregressively decodes contemplation tokens.

# Conclusion

We propose a new framework, CCoT, to generate contentful and autoregressively decoded contemplation tokens, a term we introduce to unify the terms given to tokens introducing additional computation to a language model. CCoT provides substantial improvements over the baseline as well as methods introduced by prior work. We additionally show how reasoning can be viewed as an efficiency-performance tradeoff through the adaptive compression ratio. Overall, our work demonstrates the potential of using contentful contemplation tokens as an alternative to explicit reasoning chains, suggesting a new paradigm of reasoning in continuous space.

# Appendix A: Varying the autoregressive layer

Our method CCoT autoregressively generates contemplation tokens by using the hidden state at the ```latex $l$```th layer at index ```latex $i$``` as the input embedding at index ```latex $i+1$```. We show the results of varying this autoregressive layer ```latex $l$```. We have that ```latex $l=0$``` corresponds to the embedding layer and ```latex $l=L$``` corresponds to the final layer prior to passing through the model head.

**Table 3: Accuracy on GSM8K when varying autoregressive layer**

| Autoregressive Layer | Accuracy (EM) |
|---------------------|---------------|
| NONE | 0.089 |
| l=0 | 0.087 |
| l=15 | 0.151 |
| l=31 | 0.092 |

Accuracy on GSM8K with our method CCoT with a compression ratio of ```latex $r = 0.05$``` when varying the autoregressive layer ```latex $l$```. NONE refers to the baseline where no contemplation tokens are decoded during inference.

# Appendix B: Further Theoretical Considerations

In this section, we formalize the two insights outlined in Section 6.2. We note that an analysis of the enhanced computation width provided by contemplation tokens decoded in parallel was provided by [goyal2024thinkspeaktraininglanguage]. They established a series of assumptions and defined a class of problems involving many parallel operations that a 2-layer Transformer is able to solve only if it leverages contemplation tokens.

We observe that any tasks able to be solved by decoding contemplation tokens in parallel can also be solved by decoding contemplation tokens autoregressively. We thus extend the results from [goyal2024thinkspeaktraininglanguage] by defining a more general set of problems that a 2-layer Transformer is able to solve only if it decodes contemplation tokens autoregressively.

In CCoT, contemplation tokens are decoded autoregressively by using the hidden state at the ```latex $l$```th layer as the next input. As we take ```latex $l \approx L/2$```, we adapt this framework to a 2-layer Transformer by using the only intermediate layer, ```latex $l=1$```. We formally introduce the new class of problems and outline the assumptions made by [goyal2024thinkspeaktraininglanguage] below.

**Assumption 3** (structure of underlying task). Assume a vocabulary ```latex $\mathcal{V}$``` and a embedding dimension of ```latex $d$```. Let ```latex $\circ$``` be a generic 2-ary operator on the embedding space ```latex $\mathbb{R}^d$```. For a given input length ```latex $N$```, define the class of functions ```latex $\mathcal{F}_{M, K}$``` to be the set of all functions ```latex $f: \mathcal{V}^N \to \mathcal{V}$``` that require applying computing ```latex $M$``` different ```latex $\circ$``` operations of depth ```latex $K$```, followed by a generic aggregation function ```latex $g: \mathbb{R}^{M \times d} \to \mathcal{V}$```.

Here, we assume that the vocabulary is passed into the embedding space through an embedding layer prior to the Transformer blocks. This embedding layer is given as ```latex $h: \mathcal{V} \to \mathbb{R}^d$```. We define ```latex $\mathcal{F}_{M, K}$``` symbolically as:

```latex
$$\begin{align*}
    \mathcal{F}_{M, K} = \Big\{ f: \mathcal{V}^N \to \mathcal{V} \: \Big| \: \exists T_j &\in \mathcal{P}(\{1, \cdots, N\})\\ |T_j| &= K, \forall j \in \{1, \cdots, M\}\\ f(v_1, \cdots, v_N) = g(& \bigcirc_{i \in T_1} \bar{v}_i, \ldots, \bigcirc_{i \in T_M} \bar{v}_i) \Big\}
\end{align*}$$
```

Previous work only considered the case of ```latex $K=2$``` [goyal2024thinkspeaktraininglanguage], which lends itself well to parallel tasks. This structure extends this case by considering inputs to ```latex $g$``` that require more sequential computation. Examples of these tasks that require more sequential computations include computing the sums of all triplets in a list of numbers, multi-hop QA tasks, and generally any problem requiring recursion.

The following assumptions are taken from [goyal2024thinkspeaktraininglanguage]. Further details can be found in the original paper.

**Assumption 4** (information bandwidth limit of Transformer hidden states). We assume that the hidden state corresponding to the ```latex $i$```th token at any layer can be represented as ```latex $(u_i, i)$``` by a mapping ```latex $h: \mathbb{R}^d \to \mathcal{V} \times \mathbb{N}$```.

**Assumption 5** (representational limits of Transformer operations). Let ```latex $v \in \mathbb{R}^{N \times d}$``` be a sequence of hidden states. Assume that at every index ```latex $i \in \{1, \cdots, N\}, \textsc{attn}(v)_i$``` can represent two types of functions:

- The ```latex $\circ$``` operation on the hidden states of two arbitrary indices ```latex $j, k$```. We keep the same assumptions that the self-attention module can select the two indices and the feed-forward module can implement the ```latex $\circ$``` operation, ```latex $\textsc{attn}(v)_i = v_j \circ v_k$```.

- The aggregating function ```latex $g$```, the Transformer block can represent ```latex $\textsc{attn}(v)_i = (g(v_1, \cdots, v_N), i)$```.

**Assumption 6** (the capacity of the Transformer block is independent of input length). We assume that the self-attention module has at least ```latex $2T\log T$``` parameters for some ```latex $T >> N$``` and thus can implement any of the ```latex $T^T$``` possible index mappings. This means that the self-attention module can select up to ```latex $T$``` pairs.

**Theorem 7**. Under the conditions outlined in Assumptions 3-6, the three following statements are true assuming an input sequence of length ```latex $N$```:

- Standard inference with a 2-layer Transformer can only represent the function class ```latex $\mathcal{F}_{M, 2}$``` for ```latex $M \leq N$```.

- For any ```latex $M \leq T$```, a 2-layer Transformer that decodes ```latex $M-N$``` contemplation tokens in parallel can represent the function class ```latex $\mathcal{F}_{M, 2}$```.

- For any ```latex $K > 2$```, ```latex $MK \leq T$```, a 2-layer Transformer that decodes ```latex $MK - M$``` contemplation tokens autoregressively can represent the function class ```latex $\mathcal{F}_{M, K}$```.

*Proof:* To prove the first point, it suffices to show that we can represent the function class ```latex $\mathcal{F}_{N, 2}$``` under standard inference with an input sequence length of ```latex $N$``` tokens. We demonstrate this via construction, computing ```latex $N$``` distinct ```latex $\circ$``` operations in the first Transformer block, and the aggregation in the second Transformer block. In order to represent all possible choices of pairs, we need to have the ```latex $N$``` representations of each token at the embedding layer. Expressing ```latex $N$``` representations must use all ```latex $N$``` indices by Assumption 4. We use the natural choice of using the ```latex $i$```th index to represent the ```latex $i$```th token's embedding. By Assumption 6, we can compute the ```latex $N$``` distinct ```latex $\circ$``` operations in the first Transformer block, and aggregate them using the second Transformer block. Thus, we show that we can represent ```latex $\mathcal{F}_{N, 2}$```.

To prove the second point, it suffices to show that we can represent the function class ```latex $\mathcal{F}_{N+1, 2}$``` by appending a singular contemplation token. We know from Assumption 4 that the second Transformer block can aggregate ```latex $N+1$``` inputs. Assuming ```latex $N+1 \leq T$```, the first layer can compute the addition ```latex $\circ$``` operation by Assumption 6. This argument follows by finite induction for any ```latex $N+i \leq T$```.

For the last point, we observe that the autoregressive inputs will "save" an intermediate step which allows it to be conditioned on in the same layer. For instance, to compute ```latex $\bar{v}_1 \circ \bar{v}_2 \circ \bar{v}_3$``` given the input ```latex $v = v_1v_2v_3$```, we would let the output of the first block be ```latex $\textsc{attn}(\bar{v})_3 = \bar{v}_1 \circ \bar{v}_2$```. This gets passed autoregressively as the next input, denoted as ```latex $\bar{w}$```. Then ```latex $\textsc{attn}(\bar{v})_4$``` can select the index of the new token and the index of the third token to compute ```latex $\bar{w} \circ \bar{v}_3 = \bar{v}_1 \circ \bar{v}_2 \circ \bar{v}_3$```.

In order to compute a ```latex $\circ$``` operation of depth ```latex $K$```, we need to compute the sequential prefix ```latex $\circ$``` operations of depth ```latex $K-1, \cdots, 2$```. This requires a total of ```latex $K-1$``` extra autoregressively generated contemplation tokens just to compute a single ```latex $\circ$``` operation of depth ```latex $K$```. The worst case scenario is that none of the prefix ```latex $\circ$``` operations are shared, so autoregressively decoding ```latex $M(K-1)$``` contemplations will allow us to compute all ```latex $M$``` ```latex $\circ$``` operations. We have at most ```latex $MK$``` total tokens, so given ```latex $MK \leq T$```, we can compute the desired ```latex $\circ$``` operations by Assumption 6.
