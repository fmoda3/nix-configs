# Abstract {#abstract .unnumbered}

Large Language Models (LLMs) are increasingly being used for interactive decision-making tasks requiring planning and adapting to the environment. Recent works employ LLMs-as-agents in broadly two ways: iteratively determining the next action (iterative executors) or generating plans and executing sub-tasks using LLMs (plan-and-execute). However, these methods struggle with task complexity, as the inability to execute any sub-task may lead to task failure. To address these shortcomings, we introduce **A**s-Needed **D**ecomposition **a**nd **P**lanning for complex **T**asks ([ADaPT]{.smallcaps}), an approach that explicitly plans and decomposes complex sub-tasks _as-needed_, i.e., when the LLM is unable to execute them. [ADaPT]{.smallcaps} recursively decomposes sub-tasks to adapt to both task complexity and LLM capability. Our results demonstrate that [ADaPT]{.smallcaps} substantially outperforms established strong baselines, achieving success rates up to $28.3\%$ higher in ALFWorld, $27\%$ in WebShop, and $33\%$ in TextCraft -- a novel compositional dataset that we introduce. Through extensive analysis, we illustrate the importance of multi-level decomposition and establish that [ADaPT]{.smallcaps} dynamically adjusts to the capabilities of the executor LLM as well as to task complexity.[^1]

<figure id="fig:intro" data-latex-placement="t">
[IMAGE: intro.pdf]
<figcaption> <strong>Top-Left:</strong> Iterative executors such as ReAct <span class="citation" data-cites="yao2023react"></span> interact directly with the environment, performing planning implicitly. <strong>Top-Right:</strong> Plan-and-Execute, e.g., <span class="citation" data-cites="yang2023intercode"></span>, creates a fixed plan for the task, without accounting for complexity in executing step 1. <strong>Bottom:</strong> <span class="smallcaps">ADaPT</span> dynamically decomposes based on success of the executor. </figcaption>
</figure>

# Introduction {#sec:intro}

Recent advances in Large Language Models (LLMs) have expanded their application beyond conventional NLP tasks to more complex tasks involving mathematical, symbolic, and commonsense reasoning [wei2022chain; @huang-chang-2023-towards]. Recent models have even been applied to _decision-making_ tasks, such as performing household chores, navigating a webpage, etc., that require interactions with external environments or tools [yao2023react; @qin2023toolllm].

Prior works on using LLMs for decision-making, such as ReAct [yao2023react], iteratively generate the next action to be executed in the environment given the history of actions and observations (see [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}; top-left). However, as the tasks become more complex, LLMs struggle due to their limited composition ability [dziri2023faith] and inability to deal with the distractors [Shi2023LargeLM] in a long action-observation trajectory.

To mitigate this, modular approaches [khot2023decomposed; @yang2023intercode; @Sun2023PEARLPL] incorporate a separate planner module that utilizes an LLM to create a high-level plan.[^2] The planner then delegates simpler sub-tasks to an executor LLM module thereby reducing the compositional complexity and length of action trajectory required by the executor. We refer to this category broadly as _plan-and-execute_ approaches (see [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}; top-right). While the plans enable these methods to guide the execution and track progress [wang-etal-2023-plan], their non-adaptive nature poses a limitation when confronting unachievable sub-tasks. These approaches inherently lack the flexibility to adapt to task complexity and manage execution failures, as shown in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}(top-right), where just one sub-task that is too complex results in overall task failure.

To address such failures, we propose **A**s-Needed **D**ecomposition **a**nd **P**lanning for complex **T**asks ([ADaPT]{.smallcaps}), a recursive algorithm that further decomposes sub-tasks _when necessary_, to dynamically accommodate to task complexity. We utilize separate _planner_ and _executor_ LLM modules within our framework but _only_ decompose a task using the planner, if the executor LLM detects a failure. As shown in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}, the overall task of putting a clean mug on a desk in an unfamiliar household is too complex for the model, leading to failure of the iterative executor. While a plan-and-execute-style approach initially breaks down the task into three sub-tasks, it falls short in accounting for the complexity in finding a mug. Moreover, it is challenging to anticipate the difficulty of such a sub-task in advance, as the executor could find a mug in the first attempt or in an obscure location. Therefore, [ADaPT]{.smallcaps} employs its recursive structure to _dynamically adapt_ to execution failures (assessed by LLMs), by _further decomposing_ the complex sub-task of _finding a mug_ via the planner.

Empirically, we demonstrate the effectiveness of [ADaPT]{.smallcaps} on three datasets involving interactive environments: ALFWorld [sridhar2021alfworld], WebShop [yao2022webshop], and a new compositional text game for crafting Minecraft recipes called _TextCraft_ ([4.1](#ssec:data){reference-type="ref+label" reference="ssec:data"}). Using GPT-3.5 as the underlying LLM, [ADaPT]{.smallcaps} outperforms strong baselines (discussed in [4.2](#ssec:baselines){reference-type="ref+label" reference="ssec:baselines"}) such as ReAct [yao2023react], and Plan-and-Solve [wang-etal-2023-plan] by up to $28.3\%$, $27\%$, and $33\%$ absolute points on ALFWorld, WebShop, and TextCraft respectively ([5](#sec:result){reference-type="ref+label" reference="sec:result"}). Compared to Reflexion [shinn2023reflexion], an adaptive approach that addresses _failures in the full task trajectory_, [ADaPT]{.smallcaps} yields higher success rates by $14.1\%$, $9\%$, and $20\%$ on ALFWorld, WebShop, and TextCraft respectively. Through extensive analysis of [ADaPT]{.smallcaps}, we establish the importance of recursive decomposition ([6.1](#ssec:rq1){reference-type="ref+label" reference="ssec:rq1"}) and showcase dynamic adaptation to the capabilities of the executor LLM including open-source models such LLaMA-2 [touvron2023llama] and Lemur [xu2023lemur] in [6.2](#ssec:rq2){reference-type="ref+label" reference="ssec:rq2"}. Lastly, we demonstrate that [ADaPT]{.smallcaps} incorporates task complexity ([6.3](#ssec:rq3){reference-type="ref+label" reference="ssec:rq3"}), where the extent of recursive decomposition aligns with the inherent task complexity. To summarize, our contributions are:

1.  We present [ADaPT]{.smallcaps}, a recursive algorithm that dynamically decomposes complex sub-tasks on an as-needed basis, i.e., _intervening only if the task is too complex for the executor_.

2.  On three diverse datasets, ALFWorld, WebShop, and TextCraft, [ADaPT]{.smallcaps} improves success rate of GPT-3.5 over previous approaches by up to $28.3\%$, $27\%$, and $33\%$ points respectively.

3.  Analysis of [ADaPT]{.smallcaps} underscores the significance of recursive decomposition and the ability to adapt dynamically to varying LLM execution capabilities and task complexities.

# Related Work {#sec:rel}

#### LLMs for Decision-Making.

LLMs have been successfully used as agents to perform a wide variety of decision-making tasks such as robotic navigation [ahn2022can; @huang2023inner; @singh2023progprompt], complex multi-modal games like Minecraft [fan2022minedojo; @wang2023voyager], text-based environments [sridhar2021alfworld; @liu2023agentbench]. While most of these works focus on learning from trajectories, ReAct [yao2023react] uses few-shot prompting to build an agent that reasons about the current state (thoughts) and generates the next action in the environment, given prior actions and observations. Their iterative approach (shown in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}; top-left) can handle failures, but they have to keep track of the entire plan _implicitly_ while deciding every local action (c.f. [ADaPT]{.smallcaps} in [9](#fig:alf_roll){reference-type="ref+label" reference="fig:alf_roll"} of [8](#app:details){reference-type="ref+label" reference="app:details"}). By incorporating planning and execution into separate modules and enabling dynamic adaptation we are able to achieve higher success rates (refer to [5](#sec:result){reference-type="ref+label" reference="sec:result"}).

Several follow-up works improve upon the ReAct framework by incorporating feedback in future trials [madaan2023self; @shinn2023reflexion], or using LLMs to develop heuristics for search [yao2023tree; @zhou2023language]. In contrast to [ADaPT]{.smallcaps}, they do not employ task decomposition, leading to unnecessary computation as they explore multiple trajectories or trials for the whole task, even though the LLM struggles with just one sub-task. Such works are complementary to [ADaPT]{.smallcaps} as they can be incorporated within the planner or executor modules to strengthen LLM performance (just like they are incorporated in ReAct).

#### Decomposition and Modularity.

Our work follows extensive literature in NLP on decomposing tasks into neural modules  [andreas2016neural; @gupta2019neural; @jiang-bansal-2019-self] or seq2seq models [min-etal-2019-multi; @talmor-berant-2018-web; @khot-etal-2021-text; @perez-etal-2020-unsupervised; @saha2022summarization]. With the advent of few-shot prompted black-box LLMs, this paradigm of programmatic decomposition into LLMs has become more popular [yao2023react; @khot2023decomposed; @wang-etal-2023-plan *inter alia*], referred to as LLM Programs [schlag2023large; @dohan2022language]. [ Additionally, past works in program synthesis [murali2018neural; @nye2019learning; @zheng2023outline] also employ task decomposition via generating a "program sketch" prior to program generation. ]{style="color: black"}

[ADaPT]{.smallcaps} not only decomposes tasks via the planner module and delegates them to the executor module but also _automatically_ adapts to executor failures by further decomposing complex tasks _as-needed_. This dynamic capability distinguishes [ADaPT]{.smallcaps} from prior works with a non-adaptive structure. [ADaPT]{.smallcaps} extends the recursive and hierarchical decomposition in @khot2023decomposed, enabling inter-module communications, and robust strategies for execution failures, excelling in real-world textual environments like online shopping.

#### Hierarchical Problem Solving.

In AI problem-solving, there is a longstanding tradition of hierarchical task decomposition employed in planning [ghallab2004automated; @georgievski2014overview; @holler2020hddl], reinforcement learning [sutton1999between; @barto2003recent; @nachum2018data; @zhang2021hierarchical], and navigation [she2014back; @sharma-etal-2022-skill; @blukis2022persistent; @min2022film; @song2023llm]. These approaches, such as Hierarchical Task Networks [erol1994htn], leverage domain knowledge, e.g., hand-specified library of plans, to break complex problems into simpler tasks. Our work embraces this tradition but distinguishes itself by exploring how LLMs can autonomously decompose tasks by leveraging their extensive world knowledge, without predefined plan libraries. Lastly, [ADaPT]{.smallcaps} performs dynamic hierarchical planning by employing its recursive structure.

# Methodology {#sec:method}

We introduce **A**s-Needed **D**ecomposition **a**nd **P**lanning for complex **T**asks ([ADaPT]{.smallcaps}), a modular approach for decision-making that integrates an LLM as an _executor_ and a _planner_ ([\[ssec:exec,ssec:plan\]](#ssec:exec,ssec:plan){reference-type="ref+label" reference="ssec:exec,ssec:plan"}) within an LLM program called the controller ([3.3](#ssec:cont){reference-type="ref+label" reference="ssec:cont"}). In [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}, when [ADaPT]{.smallcaps} is given a complex task, it first attempts to accomplish the entire task by running the executor iteratively, and resorting to the LLM planner for further decomposition into sub-tasks if the executor fails. Subsequently, [ADaPT]{.smallcaps} is recursively called for each sub-task to ensure their successful completion, ultimately leading to overall task success.

![ Block diagram of the [ADaPT]{.smallcaps} pipeline with an example from ALFWorld. **Left:** Use of LLM as an executor to interact iteratively with the environment along with an example execution trajectory. **Middle:** Overall recursive algorithm (depth $k \leq d_{\mathrm{max}}$) that embeds the executor and planner, refer to [[alg:main]](#alg:main){reference-type="ref+label" reference="alg:main"} for details. **Right:** Outline of using LLM as a planner to generate sub-tasks (steps) and logical operators combining them. ](images/overall){#fig:main}

## LLM as an `Executor` [IMAGE: image] {#ssec:exec}

#### Overview.

In a given environment, the executor is provided with a concise natural language task specification, as shown in [2](#fig:main){reference-type="ref+label" reference="fig:main"} (left). Following @yao2023react, the executor iteratively interacts with the environment via actions generated by the LLM. This interaction continues until the task is either completed or a preset maximum iteration limit is reached. Consistent with @ahn2022can, we provide the LLM with in-context demonstrations of low-level "atomic" skills specific to the environment (listed in [3](#tab:atomic){reference-type="ref+label" reference="tab:atomic"} of [8](#app:details){reference-type="ref+label" reference="app:details"}), such as knowing how to correctly heat objects in ALFWorld. This approach offers two advantages: (i) it allows us to employ the same executor with environment-specific knowledge for all baselines ([4.2](#ssec:baselines){reference-type="ref+label" reference="ssec:baselines"}); and (ii) it enables the planner (discussed in [3.2](#ssec:plan){reference-type="ref+label" reference="ssec:plan"}) to work at a higher level of abstraction, leveraging the LLM's general world knowledge.

#### Execution Capabilities of an LLM.

At a minimum, the LLM executor should reliably execute atomic skills. While we provide demonstrations for successful execution of atomic skills, LLMs can adapt to failures by combining multiple skills to perform complex tasks, as discussed in [6.2](#ssec:rq2){reference-type="ref+label" reference="ssec:rq2"}. For instance, in [2](#fig:main){reference-type="ref+label" reference="fig:main"} (left), we show the LLM successfully cleaning a mug it's carrying (an atomic skill). An advanced executor could combine "finding a mug" with the "cleaning" skill to accomplish "find a clean mug" without an explicit planner.

#### Self-generated Success Heuristic.

In order to decompose based on the abilities of the executor, we need to determine whether the executor is capable of finishing the given (sub-)task independently or if further decomposition is required. To this end, we employ the executor LLM to determine the completion of the (sub-)task _without relying on the environment_ for obtaining gold rewards for (sub-)tasks. We include a simple instruction in the executor prompt to output _"task completed"_ if it determines it has succeeded, otherwise output _"task failed"_ in case it cannot proceed. Refer to example in [2](#fig:main){reference-type="ref+label" reference="fig:main"} (left). Our success heuristic aligns with binary classification models employed in @shinn2023reflexion, providing a way to simulate intermediate rewards, which complements end-of-task environment rewards [rengarajan2022reinforcement]. We study this LLM-generated heuristic in [13](#ssec:comm){reference-type="ref+label" reference="ssec:comm"} and show that it closely matches the gold reward.

## LLM as a `Planner` [IMAGE: image] {#ssec:plan}

#### Overview.

The objective of the planner is to break down complex tasks into smaller sub-tasks. To achieve this, we instruct the LLM to generate a concise yet comprehensive plan consisting of a few steps, typically 3-5, as shown in [2](#fig:main){reference-type="ref+label" reference="fig:main"} (right). We opt for shorter, more abstract plans because expecting a detailed, fine-grained plan upfront can be impractical, especially in unexplored environments. E.g., devising a 10-step plan to put a clean mug on a desk without prior knowledge of the mug's location can lead to cascading errors due to incorrect assumptions. Therefore, we task the LLM to generate short plans, with the _flexibility to decompose further_ in subsequent iterations, based on the executor's capabilities.

#### Composition Logic for Sub-tasks.

Along with the sub-tasks, we prompt the planner to generate logical operators to combine various sub-tasks in the plan to accomplish the task. We allow for two logical operators: "[And]{.smallcaps}" and "[Or]{.smallcaps}". Sub-tasks are linked using [And]{.smallcaps} when they must be executed sequentially for the task to succeed. However, in cases requiring exploration, such as finding an item in an unknown room, we employ the [Or]{.smallcaps} operator to simulate conditional checks. Here, the task succeeds if any of the sub-tasks are successful. For instance, in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}, the plan to _"find a mug"_ would be to _"find a mug on the countertop" [Or]{.smallcaps} "find a mug in the cabinet"_. We execute the latter only if the agent has not found the mug yet. While examples in [\[fig:intro,fig:main\]](#fig:intro,fig:main){reference-type="ref+label" reference="fig:intro,fig:main"} show homogeneous logic, [ADaPT]{.smallcaps} can handle complex logical expressions as described in [9](#app:logic){reference-type="ref+label" reference="app:logic"}.

## `Controller` -- LLM Program [IMAGE: image] {#ssec:cont}

#### Overall Pipeline.

Thus far, we describe two LLM-based modules that can perform the roles of low-level execution and high-level planning. We incorporate these modules into [ADaPT]{.smallcaps} via the controller which is a pre-determined and recursive algorithm -- making the overall pipeline of [ADaPT]{.smallcaps} an LLM program [schlag2023large; @dohan2022language], shown in [\[alg:main\]](#alg:main){reference-type="ref+label" reference="alg:main"}. The overall flow of the controller program is as follows: (i) given an input task, the controller calls the executor to check if it can succeed in performing the task directly; (ii) if the executor does not succeed, the controller delegates decomposing the complex task to the planner and recursively calls [ADaPT]{.smallcaps} for each sub-task until we hit a termination criterion, i.e., if a maximum depth $d_{\mathrm{max}}$ ($\geq \!\! 1$) is reached.

[2](#fig:main){reference-type="ref+label" reference="fig:main"} (mid) shows the control flow of [ADaPT]{.smallcaps}. A complex task such as "put a clean mug on the desk" is first assigned to the executor. If the executor does not succeed, then [ADaPT]{.smallcaps} calls the planner to decompose the task into sub-tasks along with a logical operator ([And]{.smallcaps} or [Or]{.smallcaps}) indicating how to compose them. Each sub-task (referred to as 'step' in [2](#fig:main){reference-type="ref+label" reference="fig:main"}) is then assigned recursively to [ADaPT]{.smallcaps} and is combined using the logical operator. In the end, the success of sub-tasks after recursive decomposition ensures overall task success (unrolled calls to planner and executor are shown in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}).

# Experimental Setup {#sec:setup}

We describe the datasets used in our experiments and baselines used for comparison with [ADaPT]{.smallcaps}.

## Datasets {#ssec:data}

We employ LLMs-as-agents to perform tasks in the following three environments and use task **success rate** as our evaluation metric in [\[sec:result,sec:disc\]](#sec:result,sec:disc){reference-type="ref+label" reference="sec:result,sec:disc"}.

#### ALFWorld.

ALFWorld [sridhar2021alfworld] is a text-based game version of the embodied ALFRED benchmark [shridhar2020alfred] implemented in the TextWorld environment [cote2019textworld]. It encompasses 6 distinct task types, where an agent is required to accomplish high-level tasks through navigation and interaction via text-based actions in a simulated household that gives textual feedback to an agent (e.g., _put a clean mug on desk_ discussed earlier in [2](#fig:main){reference-type="ref+label" reference="fig:main"}). Following @sridhar2021alfworld, we present results on 134 unseen evaluation games (test set) with a separate dev set of 10 games per task from the seen evaluation games split. Along with atomic skills, we add example gold trajectories, following @yao2023react, for two tasks: heat and look in the executor prompt.[^3]

#### WebShop.

WebShop [yao2022webshop] is an online shopping website environment featuring 1.18 million real-world products containing 500 user queries in the test set. It serves as a complex decision-making environment with practical applications wherein an agent must navigate a website through a variety of commands to purchase an item matching a user specification (e.g., _grey sectional sofa priced less than \$300 with fast delivery_). Following @shinn2023reflexion, we report performance on 100 user instructions and use a different subset of 40 queries as the dev set.

#### TextCraft.

We create a new text-only environment for crafting Minecraft[^4] items similar to WordCraft [coenen2021wordcraft]. Unlike existing agent-based environments, tasks in TextCraft exhibit a natural compositional structure, resembling cooking recipes with steps of varying complexity, where some sub-tasks are more intricate, such as layering a lasagna, while others are simpler, like baking it.

<figure id="fig:textcraft" data-latex-placement="t">
[IMAGE: game.pdf]
<figcaption>Example gold trajectory in TextCraft for a task with recipe depth of 2.</figcaption>
</figure>

::: table\*
**Method ($d_{\mathrm{max}}=3$)** **Pick** **Clean** **Heat** **Cool** **Look** **Pick2** **All**

---

ReAct 33.3 [67.7]{.underline} 43.5 33.3 55.6 [11.8]{.underline} 43.3
Plan-and-Execute 29.2 61.3 47.8 38.1 **61.1** [11.8]{.underline} 43.3
Try Again with ReAct 50.0 51.6 [60.8]{.underline} 47.6 **61.1** 5.9 47.8
Reflexion 70.8 61.3 **61.0** [66.7]{.underline} **61.1** 5.9 [57.5]{.underline}
[ADaPT]{.smallcaps} (Ours) **87.5** **80.6** [60.8]{.underline} **76.2** **61.1** **52.9** **71.6**

[]{#tab:alf label="tab:alf"}

**Method** **WebShop** **TextCraft**

---

ReAct 32.0 19.0
Plan-and-Execute 17.0 27.0
Try Again with ReAct 30.0 15.0
Reflexion 35.0$^\dagger$ [32.0]{.underline}
LATS [zhou2023language] [38.0]{.underline}$^\dagger$ $-$
[ADaPT]{.smallcaps} (Ours) **44.0** **52.0**
:::

Tasks in TextCraft are inherently decomposable. In [3](#fig:textcraft){reference-type="ref+label" reference="fig:textcraft"}, crafting a beehive necessitates crafting its ingredients, like planks and honeycomb, which may require further decomposition. The agent thus needs to identify and adapt to varying task complexity, e.g., crafting a plank is _easier_ than crafting a beehive. Moreover, some recipes allow using any item from a particular category. For instance, crafting a beehive uses planks (a category), requiring the agent to use linguistic knowledge for proper item selection (e.g., select oak planks, a specific item in the category planks). We evaluate our approach on a test set of 200 tasks where the target items have recipe trees of depth 2, 3, and 4 (example tree of depth 2 is shown in [3](#fig:textcraft){reference-type="ref+label" reference="fig:textcraft"}). We use the items with recipe tree depth of 3 (123 tasks), depth of 4 (11 tasks) and depth of 2 (77 out of 297) in our test set, and the rest of depth 2 tasks constitute the dev set. Additional details about creating the environment are present in [12](#app:textcraft){reference-type="ref+label" reference="app:textcraft"}.

## Baseline Approaches {#ssec:baselines}

We compare [ADaPT]{.smallcaps} with four classes of baseline approaches described below.

#### Iterative Executor-Only (ReAct).

In this setting, we employ the executor to interact iteratively with the environment, adopting the think-act-observe prompting style from ReAct [yao2023react]. All methods discussed below, including [ADaPT]{.smallcaps}, share the _same_ executor, ensuring a standardized impact of the executor's strength and design choices when comparing relative performance in [5](#sec:result){reference-type="ref+label" reference="sec:result"}. When $d_{\mathrm{max}}\!=\!1$, [ADaPT]{.smallcaps} solely relies on this executor.

#### Plan-and-Execute.

As shown in [1](#fig:intro){reference-type="ref+label" reference="fig:intro"}, in this setting, we generate a plan first and then assign each sub-task to the executor. This approach only plans once and as a result has a non-adaptive structure (consistent with @wang-etal-2023-plan [yang2023intercode; @Sun2023PEARLPL]). To ensure each plan step is executable without further decomposition, we design new prompts with more detailed plans. Note that [ADaPT]{.smallcaps} with $d_{\mathrm{max}}\!=\!2$ differs from plan-and-execute as it is adaptive, i.e., decomposes only when executor fails and generates relatively shorter plans (refer to [9](#app:logic){reference-type="ref+label" reference="app:logic"}).

#### Try Again with ReAct.

By design, [ADaPT]{.smallcaps} makes multiple calls to the executor module, albeit with different (sub-)tasks. Like @yang2023intercode, we design a simple controller that requests the executor to retry the task in a total of $d_{\mathrm{max}}$ separate trials and then uses the trial with the best performance for each task instance.

#### Reflexion.

@shinn2023reflexion execute the entire task first, and if unsuccessful, reflect and store feedback in memory for subsequent $d_{\mathrm{max}} \! - \! 1$ trials. While adaptive, this approach repeats the entire trial even if a single sub-task fails, redundantly re-executing previously successful sub-tasks.

#### [ADaPT]{.smallcaps} and Shared Implementation Details.

Following [yao2023react; @shinn2023reflexion; @zhou2023language], by default, we use the GPT-3.5 [ouyang2022training] LLM for both planning and execution in [ADaPT]{.smallcaps} and other baselines. We use the completion-based models for ALFWorld and TextCraft and the chat-based model for WebShop.[^5] Further, we use [ADaPT]{.smallcaps} (and other baselines) with $d_{\mathrm{max}}\!=\!3$ for ALFWorld, and WebShop and increase to $d_{\mathrm{max}}\!=\!4$ for TextCraft to accommodate recipes with a depth of 4 ([4.1](#ssec:data){reference-type="ref+label" reference="ssec:data"}). For additional details, refer to [8](#app:details){reference-type="ref+label" reference="app:details"}. We increase the maximum number of iterations for the ReAct baseline by a factor of $d_{\mathrm{max}}$ and ensure all baselines use a comparable number of LLM calls ([6.5](#app:calls){reference-type="ref+label" reference="app:calls"}).

# Main Results {#sec:result}

Using GPT-3.5 as the underlying LLM, in this section, we show that [ADaPT]{.smallcaps} yields the highest success rate compared to baselines from prior work on ALFWorld, WebShop, and TextCraft datasets.

#### ALFWorld.

In [\[tab:alf\]](#tab:alf){reference-type="ref+label" reference="tab:alf"}, we observe that [ADaPT]{.smallcaps} achieves the _highest overall success rate_, while using ReAct alone results in the lowest overall performance. By leveraging adaptive decomposition, [ADaPT]{.smallcaps} improves over ReAct's performance by $28.3\%$ points (absolute) as well as over Plan-and-Execute and Try Again by $28.3\%$ and $23.8\%$ points, respectively. Lastly, we find that [ADaPT]{.smallcaps} yields $14.1\%$ points higher overall success rate than Reflexion, despite the latter having access to dedicated memory and natural language feedback. Specifically, we find baselines yield poor results on 'pick2' tasks ($<\! \! 12\%$ success rate) as they require the agent to compose two 'pick'-style tasks involving a longer action history. However, [ADaPT]{.smallcaps} yields significant improvements (by over a factor of $4\times$) for this type of tasks.

<figure id="tab:depth" data-latex-placement="t">
[IMAGE: line.pdf]
<figcaption>Success rate of <span class="smallcaps">ADaPT</span> increases with the maximum depth <span class="math inline"><em>d</em><sub>max</sub></span> for all datasets (dev splits).</figcaption>
</figure>

#### WebShop.

[\[tab:web-text\]](#tab:web-text){reference-type="ref+label" reference="tab:web-text"} shows a similar trend with _[ADaPT]{.smallcaps} surpassing all baselines_ and achieving the highest success rate. [ADaPT]{.smallcaps} outperforms ReAct, Plan-and-Execute, and Try-Again baselines by up to $27\%$ points. We corroborate the findings of @shinn2023reflexion and observe that natural language feedback offers limited gains in performance, as compared to [ADaPT]{.smallcaps} (which surpasses Reflexion by $9\%$ points). Additionally, we compare with a recent search-based baseline LATS [zhou2023language] and find that [ADaPT]{.smallcaps} outperforms the success rate of LATS by $6\%$ points.

#### TextCraft.

Our results on TextCraft are summarized in [\[tab:web-text\]](#tab:web-text){reference-type="ref+label" reference="tab:web-text"}. First, we observe that [ADaPT]{.smallcaps} _achieves an improvement of $33\%$_ compared to the ReAct executor. In contrast to Plan-and-Execute, i.e., starting with a fixed plan, having the dynamic ability to adapt to complex sub-tasks (in this case, crafting complex ingredients) in [ADaPT]{.smallcaps} improves performance by $25\%$ points. Lastly, [ADaPT]{.smallcaps} outperforms Reflexion by $20\%$ points, highlighting the importance of adaptive and as-needed planning. [ We hypothesize that [ADaPT]{.smallcaps} consistently outperforms Reflexion across datasets as the latter relies on generating feedback based on errors in the entire trajectory. In contrast, due its design, [ADaPT]{.smallcaps} often handle failures of small sub-tasks and redirects more resources in the form of calling the planner and decomposition to the challenging sub-tasks. ]{style="color: black"}

# Analysis and Discussion {#sec:disc}

We analyze [ADaPT]{.smallcaps} in detail by addressing the following research questions on dev data splits.

## How does performance of [ADaPT]{.smallcaps} scale with the depth of decomposition? {#ssec:rq1}

#### Setup.

To assess the impact of adaptive decomposition, we study [ADaPT]{.smallcaps} under three settings with increasing maximum depth $d_{\mathrm{max}} \in \{1, 2, 3\}$ for ALFWorld, WebShop, and TextCraft. Note that $d_{\mathrm{max}}\!=\!1$ setting corresponds to the iterative executor-only baseline (ReAct).

#### Results.

[4](#tab:depth){reference-type="ref+label" reference="tab:depth"} shows that across all datasets, performance of [ADaPT]{.smallcaps} scales with increasing the maximum depth $d_{\mathrm{max}}$. Consistently, we find a significant improvement in success rates as we move from $d_{\mathrm{max}}\!=\!1$ to $d_{\mathrm{max}}\!=\!2$, i.e., adding the planner to decompose a complex task when executor fails proves to be effective. Finally, the performance increase from $d_{\mathrm{max}}\!=\!2$ to $d_{\mathrm{max}}\!=\!3$ validates our hypothesis that some sub-tasks are difficult for the LLM to directly execute successfully, and decomposing these further boosts overall performance.

## Does [ADaPT]{.smallcaps} cater to different execution capabilities of LLMs? {#ssec:rq2}

<figure id="fig:setting" data-latex-placement="t">
[IMAGE: exec_sett.pdf]
<figcaption><span class="smallcaps">ADaPT</span> improves success rates across varying settings capturing different executor capabilities (i.e., executor-only performance) on ALFWorld (dev).</figcaption>
</figure>

<figure id="fig:llm" data-latex-placement="t">
[IMAGE: diff_llms.pdf]
<figcaption><span class="smallcaps">ADaPT</span> improves (test) performance of GPT-3.5, GPT-4, LLaMA, and Lemur LLMs across datasets.</figcaption>
</figure>

#### Same LLM, different execution capabilities.

We run [ADaPT]{.smallcaps} on three different executor prompts on ALFWorld: (i) task-specific gold trajectories, (ii) atomic skills and common gold-trajectories for 2 tasks used in [5](#sec:result){reference-type="ref+label" reference="sec:result"} (hybrid), and (iii) only atomic skills. Using gold trajectories aligns closely with the task at inference-time and thus, should exhibit high performance. In contrast, executor using only atomic skills relies on the inherent composition abilities of the LLM, yielding weaker performance. Here we examine if [ADaPT]{.smallcaps} can improve success rates for all three settings.

#### Results.

In [5](#fig:setting){reference-type="ref+label" reference="fig:setting"}, we observe that [ADaPT]{.smallcaps} consistently improves over the executor-only baseline for _all diverse executor settings_. As expected, the executor prompted with task-specific trajectories performs the best (left), while the executor with only atomic skills performs the worst (right). Notably, [ADaPT]{.smallcaps} substantially improves performance of the relatively weak executor, improving success rate from $3.3\%$ to $41.7\%$.

#### [ADaPT]{.smallcaps} with different LLMs.

We study the ability of [ADaPT]{.smallcaps} to improve performance across different LLMs (as planners and executors): (i) GPT-3.5, (ii) GPT-4 [openai2023gpt4], (iii) LLaMA-2 70B [touvron2023llama], and (iv) Lemur 70B [xu2023lemur] on test splits of all datasets.

#### Results.

[6](#fig:llm){reference-type="ref+label" reference="fig:llm"} shows that [ADaPT]{.smallcaps} consistently improves downstream performance for _all_ models across _all_ three datasets. Consistent with @liu2023agentbench, we find that the gated GPT models outperform the open-source models based on absolute success rates. Nevertheless, [ADaPT]{.smallcaps} is effective across LLMs and improves performance of GPT-4, the strongest LLM, by up to $37\%$, as well as LLaMA, the least performant LLM, by up to $15\%$ on the TextCraft dataset.

## Does [ADaPT]{.smallcaps} handle task complexity? {#ssec:rq3}

#### Setup.

By the compositional design of TextCraft, complexity of each task in the dataset can be defined with respect to the depth of the crafting recipe, i.e., recipes with higher depth would be more complex to craft. We evaluate efficacy of [ADaPT]{.smallcaps} and the ReAct baseline on the test set of TextCraft with increasing recipe depth.[^6] Furthermore, while we provide [ADaPT]{.smallcaps} with a maximum budget of $d_{\mathrm{max}}=4$, we study how the maximum decomposition depth utilized by [ADaPT]{.smallcaps} to succeed ($k_{\mathrm{max}}$) varies with task complexity.

::: {#tab:task2}
**Method** **Recipe Depth** **$\boldsymbol{k_{\mathrm{max}}}$** **Success Rate**

---

ReAct 2 1.0 26.9
[ADaPT]{.smallcaps} ($d_{\mathrm{max}}=4$) 2 1.9 **78.2**
ReAct 3 1.0 1.8
[ADaPT]{.smallcaps} ($d_{\mathrm{max}}=4$) 3 2.8 **38.7**

: [ADaPT]{.smallcaps} improves TextCraft (test) performance even as recipe depth increases. The maximum decomposition depth used by [ADaPT]{.smallcaps} to succeed at the task ($k_{\mathrm{max}}$) also scales with the recipe depth.
:::

#### Results.

In [1](#tab:task2){reference-type="ref+label" reference="tab:task2"} we observe that [ADaPT]{.smallcaps} improves success rates for games with recipe depth of 2 from $26.9\%$ to $78.2\%$, and of depth 3 from $1.8\%$ to $38.7\%$ as compared to the ReAct baseline. As expected, the executor alone is unable to handle complex recipes with depth $\geq 3$, but with the help of [ADaPT]{.smallcaps} the performance improves significantly. Additionally, given the same budget $d_{\mathrm{max}} \! =\! 4$, as the recipe depth (complexity) increases from $2$ to $3$, [ADaPT]{.smallcaps}'s level of decomposition ($k_{\mathrm{max}}$) also increases from $1.9$ to $2.8$. This showcases that [ADaPT]{.smallcaps} leverages as-needed decomposition in order to handle task complexity.

## Can we use different planner and executor LLMs within [ADaPT]{.smallcaps}? {#ssec:rq4}

#### Setup.

[ The planner and executor modules of [ADaPT]{.smallcaps} do not need to necessarily use the same underlying model. Following, @lin2023swiftsage we explore if a relatively smaller LLM can be used to perform local actions in the executor and a more advanced LLM be used to devise plans. To this end, we explore different combinations of planner and executor LLM, with the latter using both gated and open-source models on ALFWorld. ]{style="color: black"}

#### Results.

[ [2](#tab:combo){reference-type="ref+label" reference="tab:combo"} shows that [ADaPT]{.smallcaps} can successfully be used to generate plans from one LLM that are useful to a different, possibly smaller, executor LLM, improving success rates by up to $19.9\%$ compared to the executor-only (ReAct) setting. Interestingly, using an open-source model, such as LLaMA-2-70B-chat [touvron2023llama] can be used as an executor with a more advanced LLMs such as GPT-3.5 to improve success rates by $22.9\%$ points. Since the planner LLM is used sparingly, open-source executors can dramatically decrease the monetary or computational costs of using [ADaPT]{.smallcaps}. We defer combining knowledge from stronger and weaker LMs within [ADaPT]{.smallcaps} to future work, as examined in the context of mathematical reasoning [fu2023specializing; @saha2023can]. ]{style="color: black"}

::: {#tab:combo}
**Executor LM** **Planner LM** **Success Rate**

---

GPT-3.5 $-$ 38.4
GPT-3.5 GPT-3.5 **58.3**
LLaMA-2-70B $-$ 20.4
LLaMA-2-70B GPT-3.5 **43.3**

: [ADaPT]{.smallcaps} improves performance on ALFWorld (dev) when using different planner and executor LLMs.
:::

## How does [ADaPT]{.smallcaps} compare to baselines in terms of LLM calls? {#app:calls}

#### Setup.

[ ]{style="color: black"} [Performance of decision-making agents can be enhanced by increasing the number of calls allowed to an LLM, e.g., number of retrials in Reflexion. To verify that the gains in [ADaPT]{.smallcaps} are not simply due to higher number of LLM calls, we compare the average of number of LLM calls made by [ADaPT]{.smallcaps} to the baselines.]{style="color: black"}

<figure id="fig:calls" data-latex-placement="ht">
[IMAGE: llm_calls.pdf]
<figcaption>Average number of LLM calls for each approach including <span class="smallcaps">ADaPT</span> and baselines discussed in <a href="#ssec:baselines" data-reference-type="ref+label" data-reference="ssec:baselines">4.2</a> with GPT-3.5 LLM across datasets.</figcaption>
</figure>

#### Results.

[ [7](#fig:calls){reference-type="ref+label" reference="fig:calls"} shows that a [ADaPT]{.smallcaps} employs a comparable number of LLM calls w.r.t. Try-Again and Reflexion baselines in order to yield performance improvements discussed in [5](#sec:result){reference-type="ref+label" reference="sec:result"} ([\[tab:alf,tab:web-text\]](#tab:alf,tab:web-text){reference-type="ref+label" reference="tab:alf,tab:web-text"}). Note that while all methods including ReAct and Plan-and-Execute baselines are offered a comparable computational budget, the actual number of LLM calls used by the latter is often lower due to their inability to handle intermediate execution failures. This strengthens the argument for effectiveness of [ADaPT]{.smallcaps} as the improvements do not simply stem from using substantially higher number of calls to the LLM. ]{style="color: black"}

# Conclusion

We introduce [ADaPT]{.smallcaps}, a recursive algorithm designed to harness the planning capabilities of LLMs, dynamically decomposing complex tasks when the LLM acting as an executor encounters challenges. Our evaluation across three diverse decision-making tasks, ALFWorld, WebShop, and TextCraft, reveals impressive performance of [ADaPT]{.smallcaps}, surpassing existing baselines by substantial margins of up to $28.3\%$, $27\%$, and $33\%$ points, respectively. This not only underscores the effectiveness of [ADaPT]{.smallcaps} but also highlights the significance of as-needed decomposition in enhancing task performance. Moreover, our findings demonstrate that [ADaPT]{.smallcaps} not only adapts to the capabilities of the underlying executor LLM but also takes into account the complexity of individual task instances, showcasing its versatility and effectiveness. []{#sec:conc label="sec:conc"}

# Limitations {#limitations .unnumbered}

[ADaPT]{.smallcaps} relies on the success heuristic generated by the executor LLM to determine if the model is capable of performing a complex task. For decision-making tasks studied in this work, we find that LLMs can reliably determine task success based on past action trajectories and textual feedback from the environment (see [13](#ssec:comm){reference-type="ref+label" reference="ssec:comm"}). However, @huang2023large [stechly2023gpt4] discuss the limits of LLM's ability to self-evaluate and self-refine. In such situations, future works may additionally employ external verifiers [lightman2023let; @shridhar2023art], theory-of-mind strategies among multiple LMs [saha2023can], and other calibration and self-evaluation techniques [kadavath2022language]. These improved self-evaluation techniques could be useful to extend our framework to non-decision making tasks such as question answering.

# [ADaPT]{.smallcaps} Implementation Details {#app:details}

::: {#tab:atomic}
+---+------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | **Atomic Skill** | **Description** |
+:=:+:================:+:========================================================================================================================================================+
| | put | Assuming that the robot is carrying an object, put it on a given receptacle. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | take | Take a specified object from a specified receptacle. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | clean/heat/cool | Assuming that the robot is carrying an object, clean/heat/cool the object. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | examine | Assuming the robot is at a desk with a desk lamp, use it to look at an object. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | search | Put a given query in the search box, results in a page with list of products. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | shortlist | Based on the search page and query, get list of any matching products. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | match | Given a product ID and query, navigate to the product page and verify it matches the query. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | buy | Given a product ID and query, buy product by selecting relevant options. |
+---+------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | craft | Assuming the agent has all the ingredients in the inventory, craft a target object by picking an appropriate command from the list of crafting recipes. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | fetch | Look for a given object in the inventory or get it directly from the game. |
| +------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| | inventory | Look-up the game inventory. |
+---+------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+

: Overview of atomic skills used in [3.1](#ssec:exec){reference-type="ref+label" reference="ssec:exec"}.
:::

#### Executor.

We use a common ReAct executor for each dataset. To this end, we provide the LLM in the executor with in-context example trajectories for each atomic skill (refer to [3](#tab:atomic){reference-type="ref+label" reference="tab:atomic"} for an exhaustive list). Atomic skills are inherently task dependent, and thus, vary with the underlying environment. For ALFWorld, in which the agent needs to navigate and perform tasks in the household, the atomic skills include: taking an object, putting it down at a location, cleaning, heating, etc. On the other hand, the goal in WebShop is to buy a product based on user queries, thus, atomic skills include: searching a specified query, shortlisting products based on search page, matching if a product satisfies a criteria, and buying a product. Lastly, the atomic skills in TextCraft are fetching objects from the environment, and crafting them given the recipe and the ingredients. Following @yao2023react, we add gold trajectories for two tasks: heat and look in the executor prompt for ALFWorld, and one full gold trajectory for TextCraft.

#### Planner.

We provide the LLM with a brief description of atomic skills and in-context demonstrations of few task decompositions for each dataset.

- **ALFWorld:** The planner includes 6 demonstrations of task decompositions for one household configuration. Specifically, _"find"_ is not an atomic skill for the executor, and therefore, needs to be handled by the planner (refer to [2](#fig:main){reference-type="ref+label" reference="fig:main"}).

- **WebShop:** The planner breaks down a given task in terms of the atomic skills described in [3](#tab:atomic){reference-type="ref+label" reference="tab:atomic"} via 2 in-context demonstrations.

- **TextCraft:** The planner determines the necessary ingredients for each item and creates a plan to obtain them and then craft the item, illustrated via 2 examples with different crafting commands.

::: table\*
**Method** **Pick** **Clean** **Heat** **Cool** **Look** **Pick2** **All**

---

ReAct 66.7 41.9 47.8 80.9 [83.3]{.underline} 23.5 56.7
Plan-and-Execute [87.5]{.underline} 58.1 [73.9]{.underline} 52.4 [83.3]{.underline} 17.6 63.4
Try Again with ReAct 75.0 38.7 60.9 76.2 66.7 23.5 56.7
Reflexion 83.3 [61.3]{.underline} [73.9]{.underline} **85.7** 61.1 [29.4]{.underline} [67.2]{.underline}
[ADaPT]{.smallcaps} (Ours) **91.7** **67.7** **78.3** [81.0]{.underline} **100** **64.7** **79.8**

[]{#tab:alt_react label="tab:alt_react"}

**Method** **Score** **Success Rate**

---

Iterative Executor-Only 42.1 29.0
Static Decomposition 27.7 17.0
Retry Execution 45.4 30.0
Naive 58.3 24.0
Reflexion\* 64.2 35.0
LATS [zhou2023language]\* 75.9 38.0
[ADaPT]{.smallcaps} (Ours) 60.0 **44.0**
:::

:::: algorithm
::: algorithmic
[_// [ADaPT]{.smallcaps}$(\cdot)$ Generates success heuristic value $completed$ for the task $T$. Initialized with $k=1$._ ]{style="color: comm"} [*// Base case: terminate on reaching maximum depth*]{style="color: comm"} []{#line:3 label="line:3"} [*// Execute the task/sub-task to assess if the LLM can directly perform it using LLM-generated $success$.*]{style="color: comm"} $completed \gets \boldsymbol{\mathrm{executor}_{\textsc{llm}}}(T)$ []{#alg:line1 label="alg:line1"} [*// Plan only when the executor fails.*]{style="color: comm"} [*// Using the LLM, decompose the task into a set of sub-tasks, $\mathcal{P}$, and a Boolean function, $logic(\cdot)$, that combines output of the sub-tasks.*]{style="color: comm"} $\mathcal{P}, logic \gets \boldsymbol{\mathrm{planner}_{\textsc{llm}}}(T)$ []{#line:5 label="line:5"} [*// Get the outputs for individual sub tasks*]{style="color: gray"} $\mathcal{O} = \{\textbf{\textsc{ADaPT}{}}(T_{\mathrm{sub}}, k \! + \! 1)|{T_{\mathrm{sub}} \in \mathcal{P}}\}$ [*// Combine the outputs of the sub tasks*]{style="color: gray"} $completed \gets logic(\mathcal{O})$ $completed$
:::
::::

#### Controller.

The controller performs two crucial roles in the overall functioning of [ADaPT]{.smallcaps}. First, it serves as the _communication bridge_ between planner and executor, propagating salient information across the two depending on the task. Second, since [ADaPT]{.smallcaps} is a recursive algorithm, the controller determines the _termination criterion_ using the logical expression from the planner and success heuristic from the executor or if a maximum depth $d_{\mathrm{max}}$ ($\geq \!\! 1$) is reached. The controller propagates task-dependent salient information described below:

- **ALFWorld:** In the controller, we propagate the last successful action from a previous execution run to subsequent calls of the executor. Note that information is only propagated from successful sub-tasks. For sub-tasks connected via "[Or]{.smallcaps}", each receives the same information from the controller. Unlike @shinn2023reflexion, executor does not get text feedback from prior failures.

- **WebShop:** We propagate the current page visible to the agent along with past unsuccessful executor tasks to the planner (without any rationales). Once we find a matching product, we also propagate the product ID in future executor calls.

- **TextCraft:** We propagate the current inventory of the agent to the executor. This is akin to executors starting with the `inventory` command as the first step to keep stock of which items are missing and need to be fetched or crafted.

For partial rolled-out trajectories with [ADaPT]{.smallcaps} refer to [\[fig:alf_roll,fig:web_roll,fig:text_roll\]](#fig:alf_roll,fig:web_roll,fig:text_roll){reference-type="ref+label" reference="fig:alf_roll,fig:web_roll,fig:text_roll"}. Communication between planner and executor is highlighted in [gray box(es)]{style="background-color: light-gray"}.

#### LLM-related Hyperparameters.

Following previous works [shinn2023reflexion; @liu2023agentbench] we use `text-davinci-003` from the OpenAI API for ALFWorld. For WebShop, we use the `gpt-3.5-turbo` models, and for TextCraft we use the `gpt-3.5-turbo-instruct` models. All executors have a maximum budget of iterations to interact with the environment and execute the task. We set this budget to 20, 15, and 20 respectively for ALFWorld, WebShop, and TextCraft respectively. For try again with ReAct, we sample additional trajectories with a temperature of 0.7. As discussed in [4.2](#ssec:baselines){reference-type="ref+label" reference="ssec:baselines"}, we run the iterative executor-only baseline for 60, 45, 60 iterations for ALFWorld, WebShop, and TextCraft respectively. In [6.2](#ssec:rq2){reference-type="ref+label" reference="ssec:rq2"}, we use publicly available checkpoints for LLaMA 70B[^7] and Lemur 70B[^8] available on Huggingface [wolf2019huggingface]. For both planner and executor modules, we use a fixed prompt consisting of few in-context examples (as described above) for each dataset. We show all executor and planner prompts to the LLM in [14](#app:prompts){reference-type="ref+label" reference="app:prompts"}. Due to cost constraints, we report success rates for a single run of each LLM in [\[sec:result,sec:disc\]](#sec:result,sec:disc){reference-type="ref+label" reference="sec:result,sec:disc"}.

<figure id="fig:detail" data-latex-placement="t">
[IMAGE: detailed.pdf]
<figcaption>Illustration of how multiple levels of plans from <span class="smallcaps">ADaPT</span>, can be collapsed into one detailed plan in non-adaptive settings as used in the plan-and-execute baseline (<a href="#ssec:baselines" data-reference-type="ref+label" data-reference="ssec:baselines">4.2</a>). Our controller can handle complex (non-homogeneous) logical expressions.</figcaption>
</figure>

# Handling Complex Logic in Plans {#app:logic}

While the examples in [\[fig:intro,fig:main\]](#fig:intro,fig:main){reference-type="ref+label" reference="fig:intro,fig:main"} show homogeneous logic across sub-tasks in the plan, our controller can handle complex logical expressions including both "[And]{.smallcaps}" and "[Or]{.smallcaps}" operators. Specifically, we provide instructions to the planner to output this logical expressing at the end of the plan with a fixed prefix: `Execution Order`. We then build a deterministic parser that can parse complex logical expressions that the controller can process. We do so by splitting the logical expression into a series of homogeneous expression each passed to [ADaPT]{.smallcaps}. Whenever the task given to [ADaPT]{.smallcaps} comprises of multiple sub-tasks connected via (one) logical operator, we automatically decompose this task as per the logical expression. For example, in [8](#fig:detail){reference-type="ref+label" reference="fig:detail"}, a detailed plans used by the plan-and-execute baseline (discussed in [4.2](#ssec:baselines){reference-type="ref+label" reference="ssec:baselines"}) comprised of logical expressions using both [And]{.smallcaps}, and [Or]{.smallcaps} operators. Therefore, the parser will break automatically break this into multiple levels, i.e., Step 6 $=$ Step 1 [Or]{.smallcaps} Step 2 [Or]{.smallcaps} Step 3, followed by Step 6 [And]{.smallcaps} Step 4 [And]{.smallcaps} Step 5. While such complex logical expressions are mostly associated with the plan-and-execute baseline, they can be easily used within the [ADaPT]{.smallcaps} framework. Furthermore, this allows the plan-and-execute baseline to simulate a multi-level planning structure via detailed plans without being adaptive to the executor.

<figure id="fig:alf_roll" data-latex-placement="!ht">
[IMAGE: react_vs_adapt.pdf]
<figcaption>Comparison of iterative executors such as ReAct with <span class="smallcaps">ADaPT</span>. On left, ReAct uses interleaved “thought” statements to set milestones and track their progress. However, due to a large action history, it struggles to follow the plan exactly and hallucinates the wrong object (highlighted in red). <span class="smallcaps">ADaPT</span>, on the right, decomposes complex tasks into smaller sub-tasks whenever the executor fails, leading to shorter action trajectories for easy execution.</figcaption>
</figure>

<figure id="fig:web_roll" data-latex-placement="!ht">
[IMAGE: web_roll.pdf]
<figcaption>Partial rolled out trajectories for WebShop with <span class="smallcaps">ADaPT</span>. In the gray box we communicate to the planner the current (search) page that is visible to the agent, and once a matching product is found, we propagate it to future executor runs. Note “match on search page” corresponds to shortlist skill in <a href="#tab:atomic" data-reference-type="ref+label" data-reference="tab:atomic">3</a>, and “detail match on product page” corresponds to match skill.</figcaption>
</figure>

<figure id="fig:text_roll" data-latex-placement="!ht">
[IMAGE: text_roll.pdf]
<figcaption>Partial rolled out trajectories for TextCraft using <span class="smallcaps">ADaPT</span>. In the gray box, we propagate the inventory of the agent to subsequent executor calls. Note that while “diorite” is not directly present in the environment, i.e., it needs to be crafted. The executor LLM is able to inherently compose skills to fetch it without further decomposition.</figcaption>
</figure>

# Task-specific Executors in ALFWorld {#app:react}

In [\[tab:alf\]](#tab:alf){reference-type="ref+label" reference="tab:alf"}, we use a standardized executor with in-context demonstrations of atomic skills and two gold trajectories. While this allows for a common executor across different sub-tasks, task-specific executors yield higher performance on the specific sub-tasks. We now show [ADaPT]{.smallcaps} can also be used on top of task-specific executors used by @yao2023react. The results are shown in [\[tab:alt_react\]](#tab:alt_react){reference-type="ref+label" reference="tab:alt_react"}. First, we observe that [ADaPT]{.smallcaps} yields the overall success rate by up to $23.1\%$ points and also surpasses baselines on all but 1 task types. Interestingly, we find strong performance of the plan-and-execute baseline when using a stronger executor (as compared to [\[tab:alf\]](#tab:alf){reference-type="ref+label" reference="tab:alf"}) possibly as such an executor can handle complex sub-tasks better. Consistent with [\[tab:alf\]](#tab:alf){reference-type="ref+label" reference="tab:alf"}, [ADaPT]{.smallcaps} outperforms Reflexion by $12.6\%$ points despite lack of dedicated memory and natural language feedback.

<figure id="fig:eval" data-latex-placement="t">
[IMAGE: self_eval.pdf]
<figcaption>Comparison of LLM-generated success heuristic with gold environment rewards to compute success rates for all datasets.</figcaption>
</figure>

# Additional WebShop Experiments {#app:web}

#### Evaluation Metrics.

We focus on success rate and not the (soft) score as the primary metric for this task because it is possible to get a non-zero score by naively buying a product. To this effect, we construct a naive executor that inputs the user query in the search bar and buys the first available product. [\[tab:web-score\]](#tab:web-score){reference-type="ref+label" reference="tab:web-score"} shows that while this baseline yields the lowest success rate, it surprisingly yields a high success rate of 58.3. In contrast, our executors often do not buy products especially when the previous sub-goals fail which can adversely impact scores even though the success rate remains unaffected. Therefore, we argue for optimizing the success rate instead of the score as opposed to prior works [zhou2023language].

#### [ADaPT]{.smallcaps} accommodating task complexity.

By default, @yao2023react use a search page with only the top-3 search results displayed. Intuitively, increasing the number of products on the search page requires the model to choose from a wider array of products and track all their information to determine the best fit to the user query, making the overall task harder. Therefore, we apply [ADaPT]{.smallcaps} on Webshop in two settings with 3, and 10 products per search page.

::: {#tab:task}
**Method** **#Products** **Success Rate**

---

ReAct 3 27.5
[ADaPT]{.smallcaps} ($d_{\mathrm{max}}=3$) 3 **47.5**
ReAct 10 20.0
[ADaPT]{.smallcaps} ($d_{\mathrm{max}}=3$) 10 **42.5**

: [ADaPT]{.smallcaps} improves WebShop (dev) performance irrespective of how many products (3 or 10) are chosen from the search page.
:::

#### Results.

From [4](#tab:task){reference-type="ref+label" reference="tab:task"}, we observe that [ADaPT]{.smallcaps} effectively improves success rate by $20.0\%$ and $22.5\%$ for 3 and 10 products respectively over the ReAct baseline. The difference in ReAct performance for both settings corroborates our hypothesis that increasing number of products on the search page increases task complexity, all else equal. Notably, we show that [ADaPT]{.smallcaps} yields _higher_ improvement for _more complex_ task settings.

# TextCraft {#app:textcraft}

#### TextCraft: Environment Details.

In TextCraft, the objective is to obtain target Minecraft items by crafting them from available items in the environment. We define an environment with three actions: `craft <item> using <ingredients>`, `get <item>`, and `inventory`. We utilize Minecraft's crafting recipes to specify craftable items and their ingredients, assuming that all other items are obtainable from the environment. Similar to AlfWorld, our agent can directly execute these operations in the embodied game. The game begins with a list of crafting commands provided to the agent that detail recipes that can be used to craft the final target, its ingredients along with some distractors (details in [12](#app:textcraft){reference-type="ref+label" reference="app:textcraft"}). A reward of 1 is generated when the target item gets added to the agent's inventory. An illustrative gold trajectory from TextCraft is shown in [3](#fig:textcraft){reference-type="ref+label" reference="fig:textcraft"}.

We create the TextCraft environment using Minecraft v1.16.5 recipes. We only consider the recipes craftable using a crafting table. We consider both shapeless (only count matters) and shaped (position of ingredients matters) recipes and convert them into crafting commands (e.g. `craft 4 sticks using 2 planks`). Items that do not have any recipe are considering obtainable via the `get` command, e.g. `get 4 diamond`.

Since the entire set of crafting commands would not fit in the context of modern LLMs, we create a set of relevant crafting commands for every task. Apart from the set of gold crafting commands (i.e, crafting commands for all the items in the recipe tree), we also add up to 10 distractor commands. To create this distractor set, we sub-sample up to 10 recipes for every ingredient in the recipes of our gold recipe tree. We finally sub-sample up to 10 distractors from this entire set to ensure a reasonable context size. Note that we do not provide the list of valid `get` commands as that can be inferred from the `craft` commands.

# Evaluation of Success Heuristic {#ssec:comm}

In [3.1](#ssec:exec){reference-type="ref+label" reference="ssec:exec"}, we describe the executor module used in [ADaPT]{.smallcaps}. For tasks assigned to the executor, we prompt the LLM to generate a binary success heuristic. We use this heuristic repeatedly to evaluate if the (sub-)task needs to be decomposed further. We now study the ability of LLMs to generate this success heuristic on all our datasets. To this end, we run [ADaPT]{.smallcaps} and in the end compare the success rate when using the LLM's self-assessed task success with the gold reward from the environment in [12](#fig:eval){reference-type="ref+label" reference="fig:eval"}. On ALFWorld and TextCraft, we find the LLM slightly over-estimates its overall task success. This is to be expected as the underlying tasks involve minimal subjectivity (e.g., the agent either has an item on its inventory or not). However, on WebShop, where a product can match the user criteria to different degrees (partially or fully), we find that the LLM's assessment is significantly inflated compared to the environment reward ($>\!30$ points). This imperfect feedback affects downstream performance of [ADaPT]{.smallcaps}, as the algorithm terminates even though further decomposition is needed. We leave it to future work to address the shortcomings of self-evaluation with LLMs [huang2023large; @stechly2023gpt4].

# Prompts {#app:prompts}

We provide all the prompts used in our planner and executor modules for ALFWorld, WebShop, and TextCraft datasets in the following pages.

<figure id="prmpt:alf_exec_1">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{ALFWorld Hybrid Executor Prompt}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:alf_exec_2">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{ALFWorld Hybrid Executor Prompt (cont.)}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:alf_plan">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{ALFWorld Planner Prompt}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{peach}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:web_exec_1">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{WebShop Executor Prompt: Buy}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:web_exec_2">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{WebShop Executor Prompt: Match (cont.)}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:web_exec_3">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{WebShop Executor Prompt: Shortlist (cont.)}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure id="prmpt:web_plan">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{WebShop Planner Prompt}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{peach}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

<figure>
<div class="sourceCode" id="cb1" title="\texttt{TextCraft Executor Prompt}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</figure>

<figure>
<div class="sourceCode" id="cb1" title="\texttt{TextCraft Executor Prompt (cont.)}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{lavender}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</figure>

<figure id="prmpt:text_plan">
<div class="minipage">
<div class="sourceCode" id="cb1" title="\texttt{TextCraft Planner Prompt}" data-basicstyle="\ttfamily\scriptsize" data-backgroundcolor="\color{peach}"><pre class="sourceCode default"><code class="sourceCode default"></code></pre></div>
</div>
</figure>

[^1]: Project: <https://allenai.github.io/adaptllm>

[^2]: By "planning", we refer to the colloquial concept of designing a list of sub-tasks to accomplish a complex task rather than its usage in classical AI-planning literature. E.g., a "plan" for preparing a lasagna could be to cook the pasta, prepare the sauce, layer the ingredients, and then bake it.

[^3]: Unlike @yao2023react, we use a standardized executor prompt for all ALFWorld tasks, avoiding the agent to know the task-type apriori. [\[tab:alt_react\]](#tab:alt_react){reference-type="ref+label" reference="tab:alt_react"} in [10](#app:react){reference-type="ref+label" reference="app:react"} further demonstrates that [ADaPT]{.smallcaps} still improves over task-specific executors. []{#foot:hybrid label="foot:hybrid"}

[^4]: <https://www.minecraft.net>

[^5]: We use the completion model as chat variants of GPT-3.5 consistently underperform their completion counterparts [liu2023agentbench; @yang2023intercode]. We discuss the effectiveness of [ADaPT]{.smallcaps} different LLMs in [6.2](#ssec:rq2){reference-type="ref+label" reference="ssec:rq2"}.[]{#foot:model label="foot:model"}

[^6]: As we have only 11 tasks with recipe depth of 4, we exclude them from this analysis.

[^7]: <https://huggingface.co/meta-llama/Llama-2-70b-hf>

[^8]: <https://huggingface.co/OpenLemur/lemur-70b-chat-v1>
