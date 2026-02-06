# Abstract {#abstract .unnumbered}

We investigate the challenge of task planning for multi-task embodied agents in open-world environments.[^2] Two main difficulties are identified: 1) executing plans in an open-world environment (e.g., Minecraft) necessitates accurate and multi-step reasoning due to the long-term nature of tasks, and 2) as vanilla planners do not consider how easy the current agent can achieve a given sub-task when ordering parallel sub-goals within a complicated plan, the resulting plan could be inefficient or even infeasible. To this end, we propose "[D]{.underline}escribe, [E]{.underline}xplain, [P]{.underline}lan and [S]{.underline}elect" (**DEPS**), an interactive planning approach based on Large Language Models (LLMs). DEPS facilitates better error correction on initial LLM-generated *plan* by integrating *description* of the plan execution process and providing self-*explanation* of feedback when encountering failures during the extended planning phases. Furthermore, it includes a goal *selector*, which is a trainable module that ranks parallel candidate sub-goals based on the estimated steps of completion, consequently refining the initial plan. Our experiments mark the milestone of the first zero-shot multi-task agent that can robustly accomplish 70+ Minecraft tasks and nearly double the overall performances. Further testing reveals our method's general effectiveness in popularly adopted non-open-ended domains as well (i.e., ALFWorld and tabletop manipulation). The ablation and exploratory studies detail how our design beats the counterparts and provide a promising update on the `ObtainDiamond` grand challenge with our approach. The code is released at <https://github.com/CraftJarvis/MC-Planner>.

# Introduction {#sec:introduction}

Developing multi-task agents that can accomplish a vast and diverse suite of tasks in complex domains has been viewed as one of the key milestones towards generally capable artificial intelligence [gato; flamingo; gpt3; minedojo; jxma5]. To enable such capabilities, earlier works have suggested employing a hierarchical goal execution architecture [bacon2017option; saycan], where a planner generates action plans that would then be executed by low-level goal-conditioned controllers. This architecture has been delivering promising progress in many robotics domains, including table-top and mobile manipulation [socraticmodels; saycan], 2D shape drawing [codeaspolicies] and table rearrangement [innermonologue]. However, whether such success can be transferred to a more open-ended world with unlimited exploration areas and internet-scale knowledge remains open [minerl; minedojo; minerl-rel-1; minerl-rel-2; minerl-rel-3].

To understand the gap, we run Inner Monologue [innermonologue], a general and competitive hierarchical goal execution model on a typical open-world domain Minecraft [malmo; minerl; minedojo] and two classical robotic environments ALFWorld [alfworld] and Tabletop environments [clipport; saycan]. The algorithm uses a Large Language Model (LLM) based planner that contains domain-specific knowledge for all three environments. In all environments, we use either an Oracle goal-conditioned controller or a learned one. Results are shown in the bar plot in Figure [1](#fig:challenge){reference-type="ref" reference="fig:challenge"}. First, even when the Oracle controller is used, the success rate of executing Minecraft tasks is much less than that of the other environments. Next, the task failure rate becomes even higher in Minecraft when the learned controller is substituted. Both failures originate from unique challenges brought by open-world environments, which we identify in the following.

<figure id="fig:challenge" data-latex-placement="t">
[IMAGE: challenge.pdf]
<figcaption> <strong>Planning success rates plummet in open worlds due to new challenges</strong>.</figcaption>
</figure>

First, compared to canonical environments (e.g., Atari [atari] and robotic control suite [clipport]), open worlds have highly abundant object types with complex dependency and relation. As a result, ground-truth plans typically involve a long sequence of sub-goals with strict dependencies. As Figure [1](#fig:challenge){reference-type="ref" reference="fig:challenge"} challenge #1 suggests, it requires at least 13 sub-goals executed in proper order to obtain a diamond in Minecraft, while in Tabletop a task is typically no more than a few consecutive sub-goals.

Another challenge brought by the complicated tasks in an open-ended world is the feasibility of the produced plans. Consider the example shown in Figure [1](#fig:challenge){reference-type="ref" reference="fig:challenge"} (challenge #2). To craft a bed in Minecraft, the fastest way is by either slaughtering a sheep to obtain wool, which can be used to craft beds, or collecting beds from a village. However, since no sheep or village is reachable by the agent within 3 minutes of gameplay, to craft a bed efficiently, the agent should choose to slaughter a spider and use materials (e.g., string) it drops to craft wool, and then a bed. That is, when dealing with a task that can be completed by executing multiple possible sequences of sub-goals, the planner should be able to select the best route based on the current state of the agent. However, the complex and diverse state distribution of open-world environments makes state awareness hard to achieve.

To tackle these problems, we propose "[D]{.underline}escribe, [E]{.underline}xplain, [P]{.underline}lan and [S]{.underline}elect" (**DEPS**), an interactive planning approach based on Large Language Models (LLMs) to alleviate the aforementioned issues. The key to tackling the first challenge is to effectively adjust the generated plan upon failure. Specifically, whenever the controller fails to complete a sub-goal, a *descriptor* will summarize the current situation as text and send it back to the LLM-based planner. We then prompt the LLM as an *explainer* to locate the errors in the previous plan. Finally, a *planner* will refine the plan using information from the descriptor and explainer. To improve the feasibility of generated plans conditioned on the current state, which is the second identified challenge, we use a learned goal-*selector* to choose the most accessible sub-task based on the proximity to each candidate sub-goal.

Our experiments are conducted on 71 tasks in open-ended Minecraft without any demonstration. Given the goal-conditioned controller for atom sub-tasks (i.e., mine log and mine stone), our zero-shot[^3] LLM-based planner can finish all tasks within a limited horizon (3000-12000 steps for different tasks). We find DEPS outperforms all language planner baselines by nearly doubling the overall success rate, with the same initial state and goal-conditioned controller. Our ablation and exploratory studies then explain how our approach beats the counterparts and becomes the first planning-based agent that accomplishes the challenging `ObtainDiamond` task. DEPS does not require any planning training for the environment. Additionally, DEPS achieves between on-par and more than 50% relative improvement over existing or concurrent LLM-based planning methods on non-open-ended robotics domains such as ALFWorld [alfworld] and Tabletop environments [clipport].

# Background {#sec:background}

We aim to develop an agent capable of solving long-horizon goal-reaching tasks using image observations and language goals. To accomplish this, we propose a combined approach involving goal-conditioned policies (termed controllers) and a planner. The goal-conditioned policies are trained to complete sub-goals, while the planner decomposes long-horizon tasks into a series of `$K$` short-horizon sub-goals, `$g_1, \ldots, g_K$`, to be executed by the controller. At each time step `$t$`, the goal-conditioned policy `$\pi(a_t\mid s_t,g_k)$` generates an action `$a_t$` based on the current state `$s_t$` and the specified sub-goal `$g_k$`.

**Planning with Large Language Models.** Previous works have shown that LLMs such as InstructGPT [instructGPT] and Codex [codex] can be used as zero-shot planners to generate sub-goal sequences for various tasks in embodied environments [huang2022language; progprompt]. Formally, given the task description `$T$` as prompt `$p$`, LLM acts as a planner to decode `$T$` into `$K$` sub-goals, `$g_1, \ldots, g_K$`, which are then executed one by one by the low-level controller `$\pi(a_t \mid s_t, g_k)$` to accomplish the task.

However, the above pipeline suffers from both challenges identified in Section [1](#sec:introduction){reference-type="ref" reference="sec:introduction"}. Regarding the first challenge, the probability of generating a flawless plan directly from the task description decreases significantly as the required number of sub-goals increases. Moreover, even when the LLM generates a correct plan, it is very likely that the plan is highly inefficient given the agent's current state (challenge #2). Prior works mostly focus on solving the first challenge by providing environmental feedback to the LLM through affordance functions [saycan], success detector [codeaspolicies] or scene descriptor [innermonologue]. However, although these approaches work well on many non-open-ended domains, they still suffer from high failure rates in open-world environments.

<figure id="fig:pipeline" data-latex-placement="t">
[IMAGE: merge_architecture.pdf]
<figcaption> <strong>Overview of our proposed interactive planner architecture</strong>. </figcaption>
</figure>

# Towards Reliable Planning in Embodied Open-World Environments {#sec:method}

In this section, we first give an overview of our proposed interactive planning framework "[D]{.underline}escibe, [E]{.underline}xplain, [P]{.underline}lan, and [S]{.underline}elect" (DEPS) for solving complex and long-horizon tasks in open-world environments (Sec. [3.1](#sec:architecture){reference-type="ref" reference="sec:architecture"}). Next, in Section [3.2](#sec:descriptor){reference-type="ref" reference="sec:descriptor"}, we elaborate how DEPS iteratively refines its plan to combat the first identified challenge. Section [3.3](#sec:HPGM){reference-type="ref" reference="sec:HPGM"} introduces the *selector* module that is used to identify efficient plans in response to the second identified challenge.

## DEPS Overview {#sec:architecture}

As demonstrated in Figure [2](#fig:pipeline){reference-type="ref" reference="fig:pipeline"}, our agent (DEPS) consists of an event-triggered [D]{.underline}escriptor, a Large Language Model (LLM) as [E]{.underline}xplainer and [P]{.underline}lanner, a goal [S]{.underline}elector based on horizon prediction and a goal-conditioned controller. In the following, we use Minecraft as a running example to better elaborate our agent. Note that DEPS can be directly applied to other (non-)open-ended tasks.

We take a large language model (LLM) as a zero-shot *planner* of the agent to complete tasks. Given a goal command (e.g., `ObtainDiamond`) as task `$T$`, the LLM-based planner decomposes this high-level task into a sequence of sub-goals `$\{g_1, \ldots, g_K\}$`, as the initial plan `$P_0$`. The goals are instructions in natural language, such as `mine oak wood` [IMAGE: image] (in Minecraft), find two cups (in ALFWorld), put block A on top of block B (in Tabletop Manipulation).

As described in Section [2](#sec:background){reference-type="ref" reference="sec:background"}, a controller is then invoked to execute the provided sub-goals sequentially through a goal-conditioned policy `$\pi (a \mid s, g)$`. However, the initial plan provided by the planner often contains errors, which results in execution failures of the controller. For example, the goal [IMAGE: image] can not be finished only with a wooden pickaxe [IMAGE: image] as shown in Figure [2](#fig:pipeline){reference-type="ref" reference="fig:pipeline"}. When failure pops up, the *descriptor* will summarize the current state `$s_t$` and execution outcome of the most recent goal into text `$d_t$` and send it to the LLM. The LLM will first try to locate the errors in the previous plan `$P_{t-1}$` by *self-explanation*, e.g., the goal [IMAGE: image] need to be executed with a stone pickaxe [IMAGE: image]. Then it will re-plan the current task `$T$` and generate a revised plan `$P_t$` according to the explanation. In this process, the LLM is also treated as an *explainer* in addition to the *planner* role. The Descriptor, Explainer, and Planner will be detailed in Section [3.2](#sec:descriptor){reference-type="ref" reference="sec:descriptor"}.
```latex
$$\begin{equation}
\label{eq:pipeline}
\begin{aligned}
    \text{Description}&: d_t = f_{\text{DESC}}(s_{t-1}), \\
    \text{Explanation}&: e_t = f_{\text{EX}}(d_t), \\
    \text{Prompt}&: p_t = \text{CONCAT}(p_{t-1}, d_t, e_t), \\
    \text{Plan}&: P_t = f_{\text{LM}}(p_t), \\
    \text{Goal}&: g_t \sim f_{\text{S}}(\text{P}_t, s_{t-1}), \\
    \text{Action}&: a_{t} \sim \pi(a_t \mid s_{t-1}, g_{t})
\end{aligned}
\end{equation}$$
```


As shown in Equation ([\[eq:pipeline\]](#eq:pipeline){reference-type="ref" reference="eq:pipeline"}), DEPS will iteratively update the plan `$P_t$` until the task is finished, where `$f_\text{DESC}$` is the descriptor model, `$f_\text{LM}$` denotes the language model as explainer and planner, `$f_\text{S}$` is the selector model, `$\pi$` is goal-conditioned policies from the controller.

To filter out inefficient plans, the *selector* is trained to predict the number of time steps remaining to achieve every goal `$g_k$` in a set of parallel goals given the current state `$s_t$`. When the generated plan contains alternative routes, the selector uses this information to choose a suitable goal as the current goal `$g_t$`. For example, the horizon predicted by the selector of goal `acacia tree` [IMAGE: image] is less than goal `oak tree` [IMAGE: image] in `Savanna` biome, which leads to `chop acacia tree` as current goal `$g_t$`.

## Describe, Explain and Plan with LLM Generates Executable Plans {#sec:descriptor}

::: algorithm
``` {.python language="python"}
def craft_wooden_axe(initial_inventory={}):
    # step 1: mine 3 logs
    mine(obj = {"log":3}, tool = None)
    # step 2: craft 12 planks from 3 logs
    craft(obj = {"planks":12}, materials = {"log":3}, tool = None)
    # step 3: craft 4 sticks from 2 planks
    craft(obj = {"stick":4}, materials = {"planks":2}, tool = None)
    # step 4: craft 1 crafting_table from 4 planks
    craft(obj = {"crafting_table":1}, materials = {"planks":4}, tool = None)
    # step 5: craft 1 wooden_axe from 3 planks and 2 sticks on crafting table
    craft(obj = {"wooden_axe":1}, {"planks": 3, "stick": 2}, tool = "crafting_table")
    return "wooden_axe"
```
:::

Current LLM-based planners usually query the LLM once at the beginning of every episode and use the output plan throughout the episode [huang2022language; progprompt]. However, as demonstrated by Figure [1](#fig:challenge){reference-type="ref" reference="fig:challenge"}, such one-shot planning methods often fail on long-horizon tasks that require many sub-goals. This is caused by two major issues. First, since the correct plan for long-horizon tasks needs to respect various complex preconditions, it is extremely hard for the LLM to generate a flawless plan directly from the task instructions, resulting in failure when simply following the initial plan. Additionally, due to the unpredictable transition dynamics, some incidents may happen during the execution and make the initial plan non-executable. To remedy these problems, existing methods introduce feedback (e.g., from success detector or scene descriptor) to reflect on the results of previous executions [innermonologue; codeaspolicies; saycan]. However, merely informing the LLM whether a sub-goal is completed is often insufficient to correct the planning error.

To remedy this, we propose "describe, explain and plan", a new interactive planning method to generate more executable and explainable plans. We start with rewriting the prompt into an interactive dialogue format as in ChatGPT [instructGPT] so that subsequent feedback can be passed to the LLM effectively. The produced plan is also augmented with the preconditions and effects of each goal. The structured prompt improves the readability and interpretability of the plan and facilitates error-locating when the execution fails later, as demonstrated in Prompt [\[alg:prompt\]](#alg:prompt){reference-type="ref" reference="alg:prompt"}.

The *descriptor* will then collect the feedback generated by the agent during the execution of the task. The feedback can be practically obtained either by a person (human feedback [saycan]), or by a pre-trained vision-language model CLIP [clip]. While the previous type of feedback needs intensive human involvement, the latter from the pre-trained model needs to be fine-tuned for the specific domain, which decreases the automation and generalization of the agent. On the contrary, Minecraft returns the 'info' and other high-level observations (such as biome, GPS, and compass), we can easily translate the unstructured information into structured language. Therefore we take the symbolic information available in the game and translate it into feedback description `$d_t$` in this work. To avoid carrying unrelated information in the prompt, we further distill plan-related messages (e.g., inventory information, biome) as final event-level description `$d_t$` as demonstrated in Figure [2](#fig:pipeline){reference-type="ref" reference="fig:pipeline"}.

Notably, we also treat the LLM as an *explainer* to explain why the previous plans `$P_{t-1}$` failed. Specifically, by analyzing the current state from description `$d_t$` and precondition of current goal `$g_t$`, the explainer can identify the reason why the current goal cannot be executed successfully. As shown in Figure [2](#fig:pipeline){reference-type="ref" reference="fig:pipeline"}, the reason may be *the current goal requires the use of an iron pickaxe, but the tool is not prepared in advance, or the current goal requires the use of 3 planks, but the currently available planks are not enough*. To implement this, we provide few-shot demonstrations to the LLM as in chain-of-thoughts prompting [chainofthought], as shown in Prompt [\[alg:prompt\]](#alg:prompt){reference-type="ref" reference="alg:prompt"}. Finally, the LLM goes back to its role as a *planner* and re-plans the task with the explicit explanation of existing bugs in the previous plan `$P_{t-1}$`, ultimately generating an updated plan `$P_{t}$` according to the explanation.

## Horizon-Predictive Selector Yields Efficient Plans {#sec:HPGM}

Due to the abundance of objects and the compositional nature of their functionalities, there often exist multiple feasible plans to complete a task, i.e., there are usually multiple paths for the completion of a particular goal. However, despite the feasibility of all such plans, most of them are highly inefficient to execute in the current episode. For example, as shown in Figure [2](#fig:pipeline){reference-type="ref" reference="fig:pipeline"}, obtaining a `wood` can be done by chopping oak trees [IMAGE: image], birch trees [IMAGE: image], or acacia trees [IMAGE: image]. But only oak trees are available in the `plains` biome. So the planner needs to choose oak trees since it is more efficient, as the agent does not need to travel to another biome.

<figure id="fig:selection" data-latex-placement="t">
[IMAGE: selection.pdf]
<figcaption> <strong>Selection Demonstration from “Selector”</strong>. Given parallel sub-goals, i.e. candidate skills, our Selector will determine the sequence in which to carry out these sub-goals based on their current proximity to the agent and modify the original plan produced by the LM planner.</figcaption>
</figure>

On the other hand, there is no strict sequential requirement for some goals in the plan `$P_t$`, i.e., `$g_i, g_j \sim P_t$` enjoy the same precondition, which means `$g_i$` and `$g_j$` can be executed in any order. As shown in Figure [1](#fig:challenge){reference-type="ref" reference="fig:challenge"}, the choice of different paths (sequences) may affect the execution efficiency of the plan `$P_t$` as one goal might be closer to the agent. Always choosing the closer goal to execute first could yield more efficient plans and improve the final success rate under a limited episode length. Moreover, the dynamic nature of open-world environments further amplifies the impact of efficient plans on the success rate. For example, in Minecraft, if the agent chooses to execute a further goal like `collect wood` first, the much closer target `sheep` may disappear and be hard to find again.

In order to improve the efficiency of our plans, we propose to use a *selector* that selects the most efficient path with the highest execution success rate as the final plan. Specifically, we design a state-aware selector to choose the nearest goal under state `$s_t$` as the current goal `$g_t$` from the candidate goal sets in plan `$P_t$`. It predicts the goal distribution `$p(g_t |s_t, P_t)$` under the current state `$s_t$` and plan `$P_t$`, where `$g_t \in G_t$`, `$G_t$` describes all current executable goals in `$P_t$`. A straight way to implement the selector is to leverage the semantic similarity between the current state and the goal text using a vision-language model (VLM) such as CLIP [clip]. Nevertheless, this may not exactly reflect the difficulty of completing the goal since VLM lacks practical experience. For example, an "oak tree" in front of the agent could lead to high semantic similarity for the "chopping tree" goal, but it may be inefficient to achieve this goal if a canyon is in the middle between the agent and the oak tree.

To mitigate this, we implement a horizon-predictive selector that embeds practical task experience to accurately rank the goals based on their efficiency and feasibility. Here, we define the horizon of a goal `$h_t(g) := T_g - t$` as the remaining time steps to complete the given goal, where `$T_g$` is the time of completing goal `$g$`. This metric accurately reflects how quickly we can achieve the given goal from the current state. To estimate the horizon, we learn a neural network `$\mu$` to fit the offline trajectories by minimizing the entropy loss `$-\text{log}\ \mu(h_t(g) \mid s_t, g)$`, where `$h_t$` is the ground-truth horizon in trajectories of completing goal `$g$`. Therefore, the goal distribution can be formulated as follows:
```latex
$$\begin{equation}
    f(g_t \mid s_t,P_t) = \frac{\exp(-\mu(g_t, s_t))}{\sum_{g\in G_t} \exp(-\mu(g, s_t))}.
\end{equation}$$
```
 We set goal-sensitive Impala CNN [shaofei] as the backbone of the selector. In practice, the horizon predictive selector can be jointly trained with the controller policies and share the backbone parameters [shaofei].

# Experiments

This section analyzes and evaluates our proposed "describe, explain, plan, and select\" (DEPS) method. To minimize performance variation caused by the low-level controller, we standardize all experiments with one controller learned by behavior cloning. We refer to the details of this controller in Appendix [10](#sec:controller){reference-type="ref" reference="sec:controller"}. In Section [4.1](#sec:setup){reference-type="ref" reference="sec:setup"}, we introduce our testing environments and our evaluation task set, consisting of the hardest 71 tasks from MCU SkillForgeChain [mcu]. In Section [4.2](#sec:results){reference-type="ref" reference="sec:results"}, we report our performance in the context of existing LLM-based planners. Ablation studies are conducted in Section [4.3](#sec:ablation){reference-type="ref" reference="sec:ablation"}. Finally, we pay close attention to the hardest task, `ObtainDiamond`, which is long-hailed as a major challenge in the community. The experiments on ALFWorld and Tabletop Manipulation environments are shown in Appendix [8](#sec:other_exp){reference-type="ref" reference="sec:other_exp"}.

## Experimental Setup {#sec:setup}

::: center
:::

**Environment and Task Setting.** We first evaluate our proposed method in Minecraft, a popular open-world environment with both challenges discussed in Section [1](#sec:introduction){reference-type="ref" reference="sec:introduction"}. For better reflecting the performance of DEPS, we choose three Minecraft environments with different versions for better evaluation, including Minedojo [minedojo] with Minecraft 1.11.2, MineRL [vpt] with Minecraft 1.16.5, and MC-TextWorld [mcu] with Minecraft 1.19.2. Rules and items have something different in the above three Minecraft environments, which can better evaluate the dynamic and interactive planning abilities of DEPS.

We choose 71 tasks from the Minecraft Universe Benchmark SkillForgeChain [mcu] for evaluation. These tasks are related to items that can be obtained in the Minecraft overworld. To better present the results, we divide the 71 Minecraft tasks into 8 meta groups according to the ingredients and function of the tasks, i.e., MT1-MT8. The instruction for every task is written in natural language, e.g., `make a wooden door` in MT1 (Basic group) and `obtain a diamond` in MT8 (Challenge group), as illustrated in Table [\[tab:meta_task\]](#tab:meta_task){reference-type="ref" reference="tab:meta_task"}. Considering how long it typically takes human players to complete each task as a ballpark [minerl], we set different maximum episode steps for different meta tasks from 3000 (for easiest **Basic** tasks) to 12000 (for the hardest **Challenge** tasks). The names, number of required skills, and functions of all tasks are listed in Appendix [9](#sec:task_details){reference-type="ref" reference="sec:task_details"}. We give an empty inventory for every task in Survival mode and require the agent to obtain every item from the environment by itself. Note that our agent will be summoned in different environments randomly for each evaluation. Biomes and initial positions are also different each time. Following the previous work [malmo], we take the success rate as the evaluation metric.

**Baselines.** We compare DEPS with other language-based planners, including GPT as Zero-shot Planner(GPT) [huang2022language], ProgPrompt(PP) [progprompt], Chain-of-Thought(CoT) [chainofthought], Inner Monologue(IM) [innermonologue], and Code as Policies(CaP) [codeaspolicies]. For all baseline models, we use the same demonstration example in the prompt, the same LM model from OpenAI, and the same controller in all tasks for a fair comparison. Since these methods were not originally experimented with Minecraft, we reproduce them to conform to the Minecraft specification based on prompt and feedback template design. All planner methods access the LLM model through OpenAI API (`text-davinci-03` model [instructGPT] for GPT, CoT, and IM, and `code-davinci-02` model [codex] for PP, CaP, and Ours). All hyper-parameters of LLM (including the *temperature* and *best_of*, etc.) are kept as default. We also list the full prompt of all different methods in Appendix [14](#sec:prompt){reference-type="ref" reference="sec:prompt"}.

## Main Results {#sec:results}

Every task is executed 30 times and the average results in Minedojo [minedojo] for every meta task are listed in Table [\[tab:main_results\]](#tab:main_results){reference-type="ref" reference="tab:main_results"}. Our approach achieves the best performance with all meta tasks. As the complexity of the task increases from MT1-MT8, the planner usually needs to give more accurate task steps (i.e., longer goal sequence) to achieve the final task. Therefore the success rate of all agents decreases with the reasoning steps increasing. Starting from MT6, almost all existing LLM-based planners fail (nearly 0 success rate). DEP (w/o Selector) already consistently beats existing LLM-based planners in all meta tasks with a significant margin. This validates that "describe, explain and plan" can estimate the reason for current plan failure and correct the original flawed plans. Due to the limited maximum episode length and restricted control success rate for a hard goal (e.g., `Mine diamond with iron_pickaxe`), the final success rate is still capped.

in

In addition, *selector* also greatly improves the final task success rate of the agent (from **DEP w/o Selector** to **DEPS**). Hard meta tasks usually require the completion of multiple sub-goals (up to dozens of goals), thus bringing more flexibility and providing more candidate goals for the Selector. At the same time, as the agent conducts experiments with limited episode length, it also places high demands on the efficiency of the plan. Therefore, the Selector brings a significant improvement on efficiency-sensitive tasks such as MT7 (up to **+2.7** times success rate).

**Robustness on different controller and different Minecraft versions.** We also evaluate DEPS on MineRL [vpt] and MC-Textworld [mcu]. Note that DEPS is a planning method, which needs to equip the goal-conditioned controller for interacting with the Minecraft environments. We choose MC-Controller [shaofei] and Steve-1 [steve1] as controllers to interact with Minedojo and MineRL, respectively. These two methods are all control policies that perceive visual partial observations and produce mouse and keyboard actions. While MC-Textworld is a text world, which only keeps the Minecraft crafting recipes and mining rules. So MC-Textworld does not require the controller. The DEPS results of the task set MT1-MT8 on different Minecraft environments are shown in Table [\[tab:ablation_on_env\]](#tab:ablation_on_env){reference-type="ref" reference="tab:ablation_on_env"}. The results report that DEPS can generate effective plans in various Minecraft environments. The results on MC-Textworld [mcu] also show that the performance drops on more difficult task sets from MT6 to MT8 are mainly from the controller limitation.

## Ablation Study {#sec:ablation}

We conduct ablation experiments to investigate the number of candidate executable goals for different Selector models and the specific impact of the rounds of DEPS.

### Ablation on Selector

We verify the robustness of our proposed Selector under different parallel goals. The agent is asked to complete 2, 3, and 4 candidate goals (the precondition is consistent for all goals), respectively. The goals of the task correspond to different kinds of mobs or materials.

We report the final success rate of our method (DEP) with different selector implementations, including using a fixed sequence of goals, a random sequence of goals, and selecting a goal based on MineCLIP [minedojo], CLIP [clip], and our horizon-predictive Selector (HPS). As Figure [\[fig:ablation_goalmodel\]](#fig:ablation_goalmodel){reference-type="ref" reference="fig:ablation_goalmodel"} shows, in one round of parallel candidate goals, an improvement of `$\Delta$`=+22.3%, +29.2%, +32.6% is obtained using our horizon-predictive Selector compared to not any selector (i.e., fixed plan), respectively.

At a limited episode length, e.g., 1000 steps, goal-model shows a greater advantage, which proves that goal-model can improve the execution efficiency of the plan in embodied environments. In addition, compared to using vision-language models such as CLIP [clip] and MineCLIP [minedojo] as a goal model, horizon-predictive has the best performance due to better estimation of the horizon information. The curve trend also demonstrates that agents with Selector scale up under large amounts of goals in an open-world environment.

<figure id="fig:ablation" data-latex-placement="htbp">
<div class="minipage">
<p>[IMAGE: ablation_goalmodel_3.pdf] <span id="fig:ablation_goalmodel" data-label="fig:ablation_goalmodel"></span></p>
</div>
<div class="minipage">
<div class="center">
<p><span id="tab:ablation_on_feedback" data-label="tab:ablation_on_feedback"></span></p>
</div>
</div>
</figure>

### Ablation on Re-Planning Rounds

We evaluate our agent on all tasks with increasing maximum rounds of DEPS. The round is defined as a cycle of interactive LLM-based planning with description, explanation, and planning and selecting, i.e., an updated plan. All tasks for every maximum round are executed 30 times and the average success rate is reported in Table [1](#tab:ablation_on_feedback){reference-type="ref" reference="tab:ablation_on_feedback"}. We take the vanilla LLM planner as the baseline, in which the model takes the initially generated plan as the final execution plan, without involving any description, re-planning, or self-explanation processes during the task execution. Our results in the previous subsection utilize the maximum rounds possible under maximum tokens capped by OpenAI. We also report the success rate increment from vanilla planner to DEPS of every meta task in column `$\Delta$` in Table [1](#tab:ablation_on_feedback){reference-type="ref" reference="tab:ablation_on_feedback"}. This set of experiments demonstrates that DEPS can iteratively improve its plan in open-world environments. More description, self-explanation, and re-planning rounds produce better results, especially for hard tasks.

:::: center
::: {#tab:ablation_on_feedback}
   Rounds    0      1      3      5     `$\infty$`   `$\Delta(0\rightarrow \infty)$`
  -------- ------ ------ ------ ------ ---------- ------------------------------- --
    MT1     28.6   50.6   68.1   79.8     79.8               **+51.2**
    MT2     37.1   71.2   71.4   79.2     79.5               **+42.4**
    MT3     15.1   20.1   40.3   40.8     62.4               **+47.3**
    MT4     15.9   17.4   48.3   50.7     53.3               **+37.4**
    MT5     3.2    3.2    3.2    15.2     29.2               **+26.0**
    MT6     0.5    0.5    1.1    1.9      13.8               **+13.3**
    MT7     0.6    2.3    2.9    2.9      12.6               **+12.0**
    MT8     0.0    0.0    0.0    0.0      0.6                **+0.6**

  : Success rates of DEPS under different maximum rounds of interactive feedback.
:::
::::

## `ObtainDiamond` Challenge {#sec:bonus}

Mining diamonds in the open-world game Minecraft, i.e. MT8 in Table [\[tab:main_results\]](#tab:main_results){reference-type="ref" reference="tab:main_results"}, has been a long-standing challenge for the community [minerl]. It is challenging because mining diamonds from scratch in Minecraft involves acquiring a sequence of difficult-to-obtain items that require complex planning on goals like mining, inventory management, crafting with and without a crafting table, tool use, smelting iron ingot in a furnace, and mining at the lowest depths. We take the `ObtainDiamond` task as a bonus experiment to show the capabilities of our zero-shot planner on complex tasks in embodied environments. Previous methods' success rates on this challenge further vouch for its difficulty. [skrynnik2021forgetful; patil2020align] leverages domain-secific reward functions and RL fine-tuning to achieve `$\backsim$``<!-- -->`{=html}0.1% success rate in 15 minutes of game play. VPT further boosts the success rate to `$20\%$` within 20 minutes of play through pre-training on collects `$\backsim$``<!-- -->`{=html}70k hours human demonstrations and finetuning with human-designed reward function [vpt]. DreamerV3 is trained from scratch to collect diamonds in a modified Minecraft environment (easier to break blocks) with world models to achieve a success rate of 2% [dreamerv3].

Our DEPS manages to achieve on-par performance in this grand challenge; our agent achieves a 0.59% success rate within 10 minutes of gameplay. Note our method does not specifically fine-tune for this challenge. It is designed to be multi-task in its nature. Furthermore, considering our planner operates with demonstration prompts on a fixed Large Language Model, it can be straightforwardly adapted to other open-ended environments with modifications.

# Related Works {#sec:related_works}

**Task planning with LLMs.** There have been some methods leveraging the large language model to generate action plans for high-level tasks in embodied environments [socraticmodels; reporter; jxma4]. [huang2022language] decompose natural language commands into sequences of executable actions by text completion and semantic translation, while SayCan generates feasible plans for robots by jointly decoding an LLM weighted by skill affordances from value functions [saycan]. For better executing the plan in embodied environments, some methods use an object detector describing the initial environment into the language prompt to produce environment-suitable plans and adopt success detectors to check that each step is executed successfully [innermonologue; codeaspolicies]. [progprompt] and [codeaspolicies] use the pythonic-style prompt to produce more executable plans. However, all of the above methods assume that the initial plan from the LLM is correct. When there are bugs in the initial plan, it's difficult for the agent to finish the task successfully.

**Interactive Planning with LLMs.** Inner Monologue [innermonologue] pilots the front of interactive planning with LLMs, which introduces the feedback (including success detection and scene description) to the planner. However, we found it could still suffer from accumulative planning error, especially in long-horizon open-world tasks. Rather, our "*Describe, Explain, Plan and Select*" (DEPS) method can produce more reliable plans by leveraging chain-of-thought thinking and explanation to locate the errors in previous plans. Moreover, we also propose a goal Selector to further improve the efficiency of the plan, thereby yielding much better performances. Readers are encouraged to refer to the comparative results in Section [4.2](#sec:results){reference-type="ref" reference="sec:results"} between DEPS and these prior arts. There are also some concurrent works on planning with LLMs [reflexion; mai2023llm; text2motion; generativeagents; proagent].

**Agents in Minecraft.** Some previous works have employed the hierarchical architecture to solve long-horizon tasks in Minecraft [oh2017zero; mao2022seihai; lin2021juewu]. Recently, based on the internet-scale corpus, [minedojo] pre-trains a language-conditioned reward function and learns multi-task MineAgent. [vpt] collects a vast amount of human demonstrations to train a behavior cloning agent. More recently, [dreamerv3] utilized a learned world model to distill a policy that can efficiently explore in Minecraft. There are also some works focus on learning goal-conditioned policies for better instruction-following [shaofei; groot; steve1]. While these efforts all focus on improving the low-level controller. Rather, the planner in our architecture emphasizes applying domain knowledge to propose and arrange the sub-goals. It significantly influences the complexity and breadth of tasks that the agent can handle. Moreover, our planner is zero-shot, making it possible to generalize to other long-horizon open worlds.

# Limitations

Albeit the impressive results of our approach, we believe there are at least two major limitations within our approach. First of all, our framework relies on privately-held LLMs like GPT-3 and ChatGPT, which makes it less accessible to those who cannot afford or access the service. However, we're fully committed to ensuring a more democratized method and will explore using open-sourced models including OPT [zhang2022opt] and BLOOM [scao2022bloom]. Another issue is the explicit step-by-step planning in our system. Although it brings us superior performances over the baselines, the planning bottleneck can also prevent our model from being further scaled up. A more appealing approach will be amortizing the planning within an end-to-end trainable goal-conditioned policy, which is worth exploring next. Furthermore, some previous fundamental challenges in planning (e.g., dead ends) may not prevalent in our adopted environments and hence could be inadvertently overlooked by our paper. We are dedicated to addressing more fundamental challenges present in building a multi-task generalist agent in our series of following work.

# Conclusion

We investigate the problem of planning in open worlds. We identify two major challenges unique to these environments: 1) long-term planning requires precise and multi-step reasoning, and 2) planning efficiency could be compromised since canonical planners do not take the agent's proximity to parallel goals/subtasks into consideration. We propose "[D]{.underline}escribe, [E]{.underline}xplain, [P]{.underline}lan and [S]{.underline}elect" (**DEPS**), an interactive approach based on Large Language Models (LLMs) to tackle them both. Our experiments in the challenging Minecraft domain verify the advantages of our approach over counterparts by marking the milestone of robustly accomplishing 70+ Minecraft tasks and nearly doubling the overall performances. DEPS also is the first planning-based agent that can reach the diamond in this game.


# Additional Experiments {#sec:other_exp}

Additional experiments are conducted on the ALFWorld [alfworld] and Tabletop Manipulation environments [clipport] to showcase the generalization capabilities of DEPS.

## ALFWorld

ALFWorld [alfworld] is an interactive learning environment that aligns text and embodiment, allowing agents to acquire abstract, text-based policies in TextWorld, and subsequently execute goals from the ALFRED benchmark in a visually rich environment.

### Tasks

The ALFWorld framework contains six types (namely `Pick & Place`, `Examine in Light`, `Clean & Place`, `Heat & Place`, `Cool & Place`, `Pick Two & Place`) of tasks with various difficulty levels. Tasks involve first finding a particular object, which often requires the agent to open and search receptacles like drawers or cabinets. Subsequently, all tasks other than Pick & Place require some interaction with the object such as heating (place the object in a microwave and start it) or cleaning (wash the object in a sink). To complete the task, the object must be placed in the designated location. We sample 10 tasks from ALFWorld randomly and list all the task names, types, and the number of receptacles in Table [5](#tab:alfworld_task_list){reference-type="ref" reference="tab:alfworld_task_list"}. We classify them into 6 groups based on their functionality. For all tasks, the maximum number of steps is set as 50.

::: {#tab:alfworld_task_list}
+-------------------------------+-----+----------------------------------------+-----------------------+
| Group                         | No. | Task                                   | Number of Receptacles |
+:==============================+:===:+:=======================================+:=====================:+
| ::: {#tab:alfworld_task_list} | 1   | put some soapbottle on garbagecan      | 13                    |
|   --------------              |     |                                        |                       |
|    Pick & Place               |     |                                        |                       |
|   --------------              |     |                                        |                       |
|                               |     |                                        |                       |
|   : Task list in ALFWorld.    |     |                                        |                       |
| :::                           |     |                                        |                       |
|                               +-----+----------------------------------------+-----------------------+
|                               | 2   | put a tissuebox in dresser             | 26                    |
|                               +-----+----------------------------------------+-----------------------+
|                               | 3   | put some soapbar on drawer             | 15                    |
+-------------------------------+-----+----------------------------------------+-----------------------+
| ::: {#tab:alfworld_task_list} | 4   | put a clean soapbar in bathtubbasin    | 16                    |
|   ---------------             |     |                                        |                       |
|    Clean & Place              |     |                                        |                       |
|   ---------------             |     |                                        |                       |
|                               |     |                                        |                       |
|   : Task list in ALFWorld.    |     |                                        |                       |
| :::                           |     |                                        |                       |
|                               +-----+----------------------------------------+-----------------------+
|                               | 5   | clean some tomato and put it in fridge | 35                    |
+-------------------------------+-----+----------------------------------------+-----------------------+
| ::: {#tab:alfworld_task_list} | 6   | put a cool tomato in countertop        | 30                    |
|   --------------              |     |                                        |                       |
|    Cool & Place               |     |                                        |                       |
|   --------------              |     |                                        |                       |
|                               |     |                                        |                       |
|   : Task list in ALFWorld.    |     |                                        |                       |
| :::                           |     |                                        |                       |
|                               +-----+----------------------------------------+-----------------------+
|                               | 7   | put a cool bread in countertop         | 27                    |
+-------------------------------+-----+----------------------------------------+-----------------------+
| Heat & Place                  | 8   | heat some cup and put it in cabinet    | 36                    |
+-------------------------------+-----+----------------------------------------+-----------------------+
| Pick Two & Place              | 9   | find two cup and put them in cabinet   | 36                    |
+-------------------------------+-----+----------------------------------------+-----------------------+
| Examine in Light              | 10  | look at mug under the desklamp         | 18                    |
+-------------------------------+-----+----------------------------------------+-----------------------+

: Task list in ALFWorld.
:::

We select the GPT as Zero-Shot Planner (GPT) [huang2022language] and Inner Monologue (IM) [innermonologue] as baseline methods. For the Inner Monologue, the planning goal is the next goal among all candidate goals. For the GPT and DEP, which produce the full plan at once, the planning goal is the full plan (a goal sequence). Then the plan will be executed step-by-step, i.e., the current goal will be given to the controller and select suitable action according to the current state. The goal termination module is also employed with the LLM. For better demonstrate the effectiveness of self-explanation in DEP, we also augment the zero-shot planner with re-planning ability (GPT+RP). All planner methods access the LLM model through OpenAI API (`text-davinci-03` model [gpt3]). Since ALFWorld is a text world, the environment will be given a literal description and candidate language-conditioned actions for each state, so the controller under ALFWorld is also LLM-based. Chain-of-Thought [chainofthought] is also employed in the controller for better decision-making. All prompts for planner and controller in ALFWorld are listed in Section [14.2](#sec:alfworld_prompt){reference-type="ref" reference="sec:alfworld_prompt"}.

<figure id="fig:alfworld_demos" data-latex-placement="t">
[IMAGE: alfworld_demos.pdf]
<figcaption> <strong>Planning in the ALFWorld experiments.</strong> </figcaption>
</figure>

### Results

Each task is executed five times, and the average results for each task group are presented in Table [6](#tab:alfworld_results){reference-type="ref" reference="tab:alfworld_results"}. BUTLER is the a training-based method, the results are sourced from [alfworld]. Re-planning is a crucial capability in complex and exploratory environments. The short-horizon planning approach (IM) with re-planning capability outperforms the long-horizon planning approach (GPT) without re-planning capability with a large margin. Furthermore, the long-horizon planning method augmented with re-planning capability (GPT+RP) achieves superior performance ranging from 10% (GPT) to 52%. DEP further enhances the feasibility of planning with descriptions and self-explanation. Notably, all planning methods fail on `Place Two & Place` tasks, which is attributable to LLM's lack of requisite knowledge for this task. It is worth investigating how to effectively incorporate the distinctive knowledge of an environment into LLM.

::: {#tab:alfworld_results}
  Group               BUTLER [alfworld]   GPT [huang2022language]   GPT+RP   IM [innermonologue]    DEP
  ------------------ -------------------- -------------------------- -------- ---------------------- --------
  Pick & Place              46.0%                   33.3%             100.0%          33.3%           93.3%
  Clean & Place             39.0%                    0.0%             10.0%           50.0%           50.0%
  Cool & Place              100.0%                   0.0%             30.0%           50.0%           100.0%
  Heat & Place              74.0%                    0.0%             40.0%            0.0%           80.0%
  Pick Two & Place          24.0%                    0.0%              0.0%            0.0%            0.0%
  Examine in Light          22.0%                    0.0%             100.0%           0.0%           100.0%
  Average                   37.0%                   10.0%             52.0%           30.0%           76.0%

  : Success rates of tasks in ALFWorld.
:::

## Tabletop Manipulation

The Tabletop Manipulation experiments are conducted on a Universal Robot UR5e with a suction gripper in the simulated environments [clipport].

### Tasks

The assessment of all methods is conducted in five seen tasks, as illustrated in Table [7](#tab:cliport_task_list){reference-type="ref" reference="tab:cliport_task_list"}, wherein the seen tasks are employed for training the CLIPort [clipport] as the controller. The task involves a robotic arm equipped with a gripper, which is tasked with rearranging a number of blocks and bowls on a table to achieve a desired configuration specified via natural language (e.g., \"putting the blocks in the bowls with matching colors\").

::: {#tab:cliport_task_list}
   No         Task Name        Instruction
  ---- ----------------------- ---------------------------------------------
   1      `Assembling Kits`    Put the objects in the corresponding holes.
   2      `Towers of Hanoi`    Move the rings to the darker brown side.
   3     `Put Block in Bowl`   Match the blocks and the bowls.
   4      `Packing Shapes`     Pack the objects in the brown box.
   5    `Stack Block Pyramid`  Stack the blocks into a pyramid.

  : Task list in CLIPort.
:::

<figure id="fig:cliport_demos" data-latex-placement="h">
[IMAGE: cliport_demos.png]
<figcaption> <strong>Planning in the Tabletop Manipulation experiments.</strong> </figcaption>
</figure>

We utilized Inner Monologue (IM) [innermonologue] and Zero-shot Planner (GPT) [huang2022language] as planning baselines, in addition to comparing with a multi-task CLIPort policy directly trained on long-horizon task instructions (i.e., without utilizing LLM for planning). As CLIPort is a single-step policy that does not spontaneously terminate during policy rollout, we report CLIPort evaluations with Oracle termination (i.e., repeat until the Oracle indicates task completion) and fixed-step termination (i.e., repeat for `$k$` steps). For Inner Monologue, which directly produces the next-step goal and terminates when the LLM ceases to generate new steps, we similarly set the maximum number of steps to be `$k$` for practical considerations. For the zero-shot planner [huang2022language] and our DEP, which produce the full plan at once, they are augmented with the LLM-based termination. DEP also involves the description, explanation, and re-planning process. The same `$k$` step is suitable for these two methods. In practice, `$k$` is set as 15. The prompts for all methods are listed in Section [14.3](#sec:tabletop_prompt){reference-type="ref" reference="sec:tabletop_prompt"}. We use the checkpoints provided by CLIPort as the controller and all planner methods access the ChatGPT (as LLM) through OpenAI API (`gpt-3.5-turbo` model). Each task is evaluated 5 times with different seeds.

### Results

The results of each method are listed in Table [8](#tab:cliport_results){reference-type="ref" reference="tab:cliport_results"}. All LLM-based planning methods perform well on tabletop rearrangement tasks. Given the compact nature of the tabletop environment, the performance gap among the various LLM-planning methods is not as pronounced as in the open-ended Minecraft. This observation underscores the robust generalization capabilities of LLM-based planning methods across diverse environments.

::: {#tab:cliport_results}
  Task                     CLIPort [clipport] +oracle   GPT [huang2022language]   IM [innermonologue]    DEP
  ----------------------- ----------------------------- -------------------------- ---------------------- --------
  `Assembling Kits`                   60.0%                       60.0%                    60.0%           60.0%
  `Towers of Hanoi`                  100.0%                       100.0%                   40.0%           100.0%
  `Put Block in Bowl`                100.0%                       100.0%                   82.0%           100.0%
  `Packing Shapes`                    40.0%                       40.0%                    60.0%           40.0%
  `Stack Block Pyramid`               80.0%                       100.0%                   40.0%           100.0%
  Average                             76.0%                       80.0%                    56.4%           80.0%

  : Success rates for various methods across different tasks in Tabletop Manipulation environment.
:::

# Minecraft Task Details {#sec:task_details}

To fully validate the multitask planning and execution capability of our agent, we choose over 70 tasks from the Minecraft Universe Benchmark [mcu] as the set of evaluation tasks. These tasks are related to items that can be obtained in the Minecraft overworld. These tasks are also a subset of MineDojo [minedojo] programmatic tasks. Minedojo exists some programmatic tasks sharing the same object item given different conditions (e.g., obtain wool given shear or obtain wool given nothing). Minedojo expands the richness of the same tasks (sharing the same Minecraft item as an object) by giving different initial conditions (e.g., `obtain wool given shears` or `obtain wool given nothing`). We keep only the 71 hardest conditions (i.e. `given nothing`) as tasks.

We list all task names, objects, and their required skills number for planning from Table [\[tab:mt1_task_list\]](#tab:mt1_task_list){reference-type="ref" reference="tab:mt1_task_list"} to Table [\[tab:mt8_task_list\]](#tab:mt8_task_list){reference-type="ref" reference="tab:mt8_task_list"}. Object item is used as the basis for the successful completion of the task. These objects cannot be obtained directly from the environment, and usually require multiple goals (i.e., reasoning steps) to be constructed. Here we only consider the number of required goal types, and multiple identical goals are unified into 1 reasoning step. Note that the reasoning steps for each task are not fixed, and as the initial state of the agent and the biome is in change, more reasoning steps may be required to complete it, we only report the most basic case here.

As shown in Figure [\[fig:ablation_goalmodel\]](#fig:ablation_goalmodel){reference-type="ref" reference="fig:ablation_goalmodel"}, for each task, a relaxed (longer) maximum episode steps will increase the success rate of the task. To fully test the efficiency of our method, we set an upper limit on the episode length for each task. Since different tasks have different difficulty levels, we double the average completion time of human players for different meta-tasks as the upper limit of the episode. The play time are computed as corresponding maximum steps (i.e., Max. Steps in Table [\[tab:meta_task\]](#tab:meta_task){reference-type="ref" reference="tab:meta_task"}) of episode length at 20Hz.

# DEPS Implementation Details  {#sec:controller}

We study three different implementations of DEPS for each of the experimental settings. While each version incorporates description and self-explanation to improve planning of LLM, there are differences in the internal components of each system, as seen in Table [9](#tab:implementation_comparison){reference-type="ref" reference="tab:implementation_comparison"}.

[]{#tab:implementation_comparison label="tab:implementation_comparison"}

::: {#tab:implementation_comparison}
               **Minecraft**               **ALFWorld**        **Tabletop Manipulation**
  ------------ --------------------------- ------------------- ---------------------------
  LLM          `code-davinci-02`           `text-davinci-03`   `gpt-3.5-turbo`
  Controller   Behavior Cloning Learned    LLM-based           CLIPort
  Descriptor   Inventory Description       Env Support         heuristics
  Explainer    LLM-based                   LLM-based           LLM-based
  Selector     Horizon Prediction Module   N/A                 N/A

  : Comparison between different versions of DEPS implemented in three different environments.
:::

## Controller

As the name implies, tasks in Minecraft are usually related to `mine` and `craft` goals. `Mine` goals require the agent to collect raw materials from the environment using the appropriate tools. `Craft` goals ask the agent to synthesize using existing materials. Any raw material used requires the agent to collect through suitable tools (e.g., diamonds can only be collected by an iron pickaxe or a better pickaxe). So a task usually requires dozens of step-by-step `mine` and `craft` goals, as the required skills in Table [\[tab:mt1_task_list\]](#tab:mt1_task_list){reference-type="ref" reference="tab:mt1_task_list"}. Note that the successful execution of a task needs to satisfy certain exact numerical constraints due to the presence of strict generation recipes in the environment (e.g., a log can craft 4 planks, so harvesting 6 planks requires at least 2 logs). When the number of materials collected is not enough, the goal cannot be completed successfully. When more materials are collected than actually needed, the execution success rate of the task could also be reduced because the plan can not be finished under the maximum action steps.

[]{#tab:skill_success_rate label="tab:skill_success_rate"}

::: {#tab:skill_success_rate}
+--------+------------------------------------+--------------+----------------+
| ID     | Skill Description                  | Success Rate | Episode Length |
+:======:+:===================================+:============:+:==============:+
| 0      | Mine 1 oak wood                    | 0.39         | 600            |
+--------+------------------------------------+--------------+----------------+
| 1      | Mine birch wood                    | 0.29         | 600            |
+--------+------------------------------------+--------------+----------------+
| 2      | Mine 1 cobblestone with pickaxe    | 0.95         | 600            |
+--------+------------------------------------+--------------+----------------+
| 3      | Mine 1 stone with pickaxe          | 0.70         | 600            |
+--------+------------------------------------+--------------+----------------+
| 4      | Mine 1 seed                        | 0.18         | 600            |
+--------+------------------------------------+--------------+----------------+
| 5      | Mine 1 leaves with shears          | 0.68         | 600            |
+--------+------------------------------------+--------------+----------------+
| 6      | Mine 1 dirt                        | 0.54         | 600            |
+--------+------------------------------------+--------------+----------------+
| 7      | Mine 1 iron ore with stone pickaxe | 0.40         | 3000           |
+--------+------------------------------------+--------------+----------------+
| 8      | Mine 3 iron ore with stone pickaxe | 0.16         | 3000           |
+--------+------------------------------------+--------------+----------------+
| 9      | Mine 1 diamond with iron pickaxe   | 0.35         | 12000          |
+--------+------------------------------------+--------------+----------------+
| 10     | Mine 1 diamond with stone pickaxe  | 0.00         | 12000          |
+--------+------------------------------------+--------------+----------------+
| 11     | Kill 1 sheep with axe              | 0.44         | 600            |
+--------+------------------------------------+--------------+----------------+
| 12     | Kill 1 cow with axe                | 0.60         | 600            |
+--------+------------------------------------+--------------+----------------+
| 13     | Kill 1 chicken with axe            | 0.46         | 600            |
+--------+------------------------------------+--------------+----------------+
| 14     | Kill 1 pig with axe                | 0.49         | 600            |
+--------+------------------------------------+--------------+----------------+
| 15     | Kill 1 llama                       | 0.50         | 600            |
+--------+------------------------------------+--------------+----------------+
| 16     | Equip tool on mainhand             | 1.00         | 600            |
+--------+------------------------------------+--------------+----------------+
| 17-261 | Craft w/o crafting_table           | 1.00         | 600            |
|        +------------------------------------+--------------+----------------+
|        | Craft w/ crafting_table            | 0.90         | 600            |
|        +------------------------------------+--------------+----------------+
|        | Smelt w/ furnace                   | 0.80         | 600            |
+--------+------------------------------------+--------------+----------------+

: The success rate of different skill/goal with imitation learning controller.
:::

We designed the agent's skill space based on these goals, as shown in Table [10](#tab:skill_success_rate){reference-type="ref" reference="tab:skill_success_rate"}, with a total of 262 goals. Every goal is designed with an objective item (e.g., 1 `minecraft:cobblestone` for skill "`Mine 1 cobblestone with pickaxe`"), which is used to evaluate the achievement of the goal. The skill, as a goal-conditioned policy `$\pi(a|s, g)$` for decision-making, maps the current state `$s$` and goal `$g$` to action `$a$`. The goal is specified as natural language instructions here, which is similar to [saycan].

When training the controller, we adopt the observation space provided by MineDoJo [minedojo], which includes an RGB camera view, yaw/pitch angle, GPS location, and the type of `$3 \times 3$` blocks surrounding the agent. We discretize the original multi-discrete action space provided by MineDojo into 42 discrete actions. We use the proposed imitation learning method proposed by [shaofei] in training. To be specific, a modified goal-sensitive Impala CNN is used as the backbone network. The success rate under a fixed episode length of every skill is listed in Table [10](#tab:skill_success_rate){reference-type="ref" reference="tab:skill_success_rate"}.

## LLM as Planner

DEPS relies on Large Language Models (LLMs) to generate language-based plans. In our Minecraft experiment, we chose Codex [codex] as the LLM Planner because it can accept longer input tokens and is cost-effective. However, DEPS is compatible with various types of LLMs. Therefore, we used GPT3 [gpt3] and ChatGPT as LLM Planners in the ALFWorld and Tabletop Manipulation experiments, respectively. Due to the effective planning and error correction performance of DEPS, the initial plan generated by the LLM has little impact on the final performance of the Agent. We also conduct ablation experiments on

even if the initial plan generated by the LLM has low accuracy, DEPS can generate a final feasible plan through self-explanation and re-planning. Therefore, we conducted ablation experiments on LLM in Minecraft.

We choose Codex [codex], ChatGPT, GPT3 [gpt3], and recent GPT-4 [gpt4] as Planners. We used Vanilla Planner [huang2022language] as baselines and excluded the re-planning process. Given the same prompt with DEPS, the performance of baseline models reflects the planning ability of different LLMs. The success rate of baseline and DEPS on different LLMs are reported in Table [11](#tab:ablation_on_llm){reference-type="ref" reference="tab:ablation_on_llm"}.

:::: adjustbox
width=0.7

::: {#tab:ablation_on_llm}
+-------+--------------------+--------------------+-----------------+--------------------+
| Group | Codex [codex]     | GPT-3 [gpt3]      | ChatGPT         | GPT-4 [gpt4]      |
+:=====:+:========:+:=======:+:========:+:=======:+:========:+:====:+:========:+:=======:+
| 2-3   | baseline | DEPS    | baseline | DEPS    | baseline | DEPS | baseline | DEPS    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT1   | 28.6     | 79.8    | 27.2     | 75.4    | 20.3     | 70.2 | 49.2     | 89.3    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT2   | 37.1     | 79.5    | 42.1     | 76.3    | 28.2     | 68.5 | 48.3     | 85.0    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT3   | 15.1     | 62.4    | 7.8      | 58.7    | 3.2      | 50.4 | 38.04    | 63.4    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT4   | 15.9     | 53.3    | 6.7      | 50.2    | 4.8      | 47.8 | 27.0     | 55.7    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT5   | 3.2      | 29.2    | 2.7      | 17.2    | 0.8      | 16.3 | 15.7     | 32.2    |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT6   | 0.5      | 13.8    | 0.3      | 7.9     | 0.3      | 6.0  | 4.9      | 16.19   |
+-------+----------+---------+----------+---------+----------+------+----------+---------+
| MT7   | 0.6      | 12.6    | 0.4      | 5.3     | 0.5      | 5.2  | 3.1      | 16.41   |
+-------+----------+---------+----------+---------+----------+------+----------+---------+

: Success rates for different LLMs on Minecraft tasks.
:::
::::

The success rate of Vanilla Planner varies on the LLMs. The GPT-4 baseline achieved an initial plan accuracy twice as high as the baselines on other LLMs, demonstrating superior planning ability. After being augmented by Descriptor, Explainer, and Selector, DEPS based on different LLMs showed almost identical success rates. This indicates that DEPS-augmented LLMs can generate more feasible plans in open-world environments even if the initial plan is less successful.

It is noteworthy that DEPS is constrained by the maximum token limits of various models, which dictate the maximum re-planning rounds that can be supported. Longer re-planning rounds tend to yield superior performance, particularly in long-horizon tasks requiring more skills (in MT6-MT7), as detailed in the Section [4.3](#sec:ablation){reference-type="ref" reference="sec:ablation"}.

Since we use pretrained LLM as a planner, it indeed requires exposure to a large amount of Minecraft-related corpus during the pretraining phase. Considering that Minecraft is one of the most popular games worldwide, there is relatively abundant data about Minecraft available online. We conducted experiments using open-source pretrained LLaMA2-70B on several Minecraft tasks and found that DEPS based on LLaMA2 also performs reliable planning under Minecraft conditions. Considering limited training data used by LLaMA2, we further finetuned an open-source language model (LLaMA2-13B) using Minecraft texts obtained from the internet which exhibited better planning performance. The results are shown in Table [\[tab:llama_results\]](#tab:llama_results){reference-type="ref" reference="tab:llama_results"}.

## LLM as Explainer

Given the description and previous plan, the explainer can generate a self-explanation of the failure of the current plan and give instructions to fix the bugs. The explainer is implemented with the OpenAI completion mode based on `text-davinci-03` models. The prompt for the explainer is listed in Listing [\[lst:explainer_prompt\]](#lst:explainer_prompt){reference-type="ref" reference="lst:explainer_prompt"}.

     % [language=python]

    Here are some actions that the agent fails to perform in Minecraft. Please give the explanation of action execution failure according to the current inventory information of the agent.

    ###
    Failed Action: mine({'iron_ore':1}, null); # step 5: mine 1 iron_ore without tool
    Current Inventory: null
    Explanation: Because mining iron_ore needs to use the tool stone_pickaxe, but my inventory does not have stone_pickaxe. So I need to craft stone_pickaxe first.

    ###
    Failed Action: craft({'stone_pickaxe':1}, {'cobblestone':3, 'stick':2}, 'crafting_table'); # step 1: craft 1 stone_pickaxe from 3 cobblestone and 2 stick, on crafting_table
    Current Inventory: null
    Explanation: Because crafting stone_pickaxe needs to have 3 cobblestone and 2 stick in inventory, but my inventory does not have cobblestone and stick. So I need to mine cobblestone and craft stick first.

    ###
    Failed Action: craft({'stick':4}, {'planks':2}, null); # step 3: craft 4 stick from 2 planks first
    Current Inventory: null
    Explanation: Because crafting stick needs to have planks in inventory, but my inventory does not have planks. So I need to craft planks first.

    ###

## Other modules

**Goal Parser.** We need to map the plan expressed in free-form language to the pre-defined controller skills set. We use the LLM as an automatic parser to parse the language plan first. For the goals not following pre-defined code expression, we calculate its semantic distance to the skills by cosine similarity with pre-trained Sentence-Bert model [sentencebert] and select the most similar skill as the corresponding goal. All executable goals are listed in Appendix [10](#sec:controller){reference-type="ref" reference="sec:controller"}. The LLM-based parser is general and can be transferred to other domains easily by modifying the prompt. The prompt for Minecraft parser is listed in Listing [\[lst:parser_prompt\]](#lst:parser_prompt){reference-type="ref" reference="lst:parser_prompt"}.

     % [language=python]

    Extract the action name, action type, goal object, tool and action rank from the input text.

    input: mine({'log':3}, null); # step 1: mine 3 log without tool
    name: mine_log
    action: mine
    object: {'log':3}
    tool: null
    rank: 1
    ###

    input: craft({'planks':12}, {'log':3}, null); # step 2: craft 12 planks from 3 log
    name: craft_planks
    action: craft
    object: {'planks':12}
    materials: {'log':3}
    tool: null
    rank: 2
    ###

**Success Detector.**

The successful execution of a plan is contingent upon the agent's perception of the current goal's completion status, which is assessed by the success detector. In Minecraft, agents possess an inventory that contains all pertinent information regarding the agent's current state. Thus, the Success Detector can be implemented by monitoring changes in object information within the item inventory. In other scenarios, we can query the LLM to ascertain whether the agent has accomplished a general goal by describing the agent's current state. Alternatively, in certain environments [clipport], the execution of a goal is linked to the agent's current reward, signifying that these rewards can serve as automatic success detectors.

**Prompt.** The generalization of the LLM to different tasks relies on well-designed prompts and related demonstrations [min2022rethinking]. Given an instruction command (e.g., `ObtainDiamond`) as task `$T$`, a prompt generator (ProG) will translate `$T$` into prompt text. We also added two DEP examples in the prompt as demonstrations to make the LLM output familiar to the chain-of-thought thinking and structural output. We also design a chain-of-thought code-comments-type planning prompt to better demonstrate the capabilities of LLM. All messages are modified to suitable prompts through the prompt-generator before being input to LLM, including task `$T$` and description `$d_t$`. The full prompt sentences and interaction logs are listed in Appendix [15](#sec:interaction){reference-type="ref" reference="sec:interaction"}.

# Comparison with other LLM-based Planners {#sec:planner_comparison}

The architectures of the different LLM-based planners are illustrated in Figure [7](#fig:planner_comparison){reference-type="ref" reference="fig:planner_comparison"}. Where (b) describes the information in the environment into LLM via scene descriptor and success detector, and directly plans the next goal/action, (c) is Zero-Shot planner [huang2022language], which generates the step-by-step goal sequences as plan and ignores the environment state and execution feedback, (d) is the Zero-Shot planner augmented with textual feedback and re-planning process. DEPS further rethink and explain the feedback of previous plans explicitly with the descriptor and explainer. The LLM-based planner will re-plan the task according to the explanation, as demonstrated in Figure [7](#fig:planner_comparison){reference-type="ref" reference="fig:planner_comparison"}(a). In addition, the goal Selector further improves the executability of the LLM plan.

<figure id="fig:planner_comparison" data-latex-placement="t">
[IMAGE: architecture_2.pdf]
<figcaption> <strong>Comparison of LLM-based planner architecture</strong>. (a), (b), (c), (d) represents planner of ours, Inner Monologue <span class="citation" data-cites="innermonologue"></span>, Zero-Shot Planner <span class="citation" data-cites="huang2022language"></span> and Zero-Shot Planner with re-planning process, respectively. </figcaption>
</figure>

# Discussion on `ObtainDiamond` Task {#sec:obtain_diamond_task}

<figure id="fig:obtain_diamond_task" data-latex-placement="h">
[IMAGE: appendix_obtain_diamond_process.pdf]
<figcaption> <strong>The milestone goals of the <code>ObtainDiamond</code> task.</strong> </figcaption>
</figure>

As outlined in Section [4.4](#sec:bonus){reference-type="ref" reference="sec:bonus"}, `ObtainDiamond` task is a formidable task within the open-ended Minecraft environment. Given the necessity to explore an infinitely expansive world, an efficient plan can prove advantageous, as shown in Figure [8](#fig:obtain_diamond_task){reference-type="ref" reference="fig:obtain_diamond_task"}. The task is allotted a maximum of 12,000 steps to interact with the environment, which is comparable to that of human performance [minerl]. Rather than manually devising explicit hierarchical rewards, we opt to utilize DEPS for generating a hierarchical plan, which is then transferred to the downstream controller to progressively achieve each goal. When equipped with an **Oracle** Controller, DEPS yields a success rate of 60% for ObtainDiamond. In our experimentation, we employed Behavior Cloning to train a Controller agent [shaofei]. DEPS+BC Controller achieved a success rate of 0.6% in randomly generated Minecraft worlds. The primary bottleneck impeding overall agent success rate lies within the goal-conditioned Controller, not the plans generated by DEPS. Thus, it is worth exploring the development of a data-efficient Controller capable of accepting Language goals.

Another rationale for using DEPS is that, akin to reality, materials in Minecraft possess quantity constraints, and durability for tools. In `ObtainDiamond` task, an iron pickaxe is typically insufficient to support the agent, given the rarity of diamonds within the environment (which are predominantly found between depths of 2-16 layers and appear only 0.0846% of the time). The robust re-planning capabilities of DEPS can facilitate the generation of a feasible plan (initiating with crafting an iron-pickaxe) based on the agent's current state.

Additionally, we report the milestones, which demonstrate the decreasing success rate of subsequent tasks in Figure [9](#fig:ObtainDiamond){reference-type="ref" reference="fig:ObtainDiamond"} attributable to the task's inherent complexity and Controller constraints.

<figure id="fig:ObtainDiamond" data-latex-placement="h">
[IMAGE: ObtainDiamond.pdf]
<figcaption> <strong>Success rate of milestone items for mining diamond</strong>. </figcaption>
</figure>

# Success Rates of ALL Tasks in Minecraft {#sec:success_rate_list}

We report the complete and detailed success rate table of all tasks for different methods in Table [\[tab:full_results\]](#tab:full_results){reference-type="ref" reference="tab:full_results"}, including Zero-shot Planner [huang2022language], ProgPrompt [progprompt], Chain-of-Thought [chainofthought], Inner Monologue [innermonologue], Code as Policies [codeaspolicies], and proposed methods (i.e., DEP w/o Selector, and DEPS).

All tasks are executed for at least 30 times across different world seeds, given the same initial conditions. The birth positions of the world are random according to the seed. The average success rates are listed in Table [\[tab:full_results\]](#tab:full_results){reference-type="ref" reference="tab:full_results"}. Our approach is state-of-the-art on almost all tasks, especially on difficult tasks that require more skills.

# Prompt for Different Tasks and Different Methods {#sec:prompt}

## Prompt for Minecraft Tasks {#sec:minecraft_prompt}

### DEPS

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    ==========
    User: How to obtain 1 wooden_button in Minecraft step-by-step?
    Planner: The code for obtaining 1 wooden_button is as follows:
    def obtain_1_wooden_button(inventory={}):
        mine({'log':1}, null); # step 1: mine 1 log without tool
        craft({'planks':4}, {'log':1}, null); # step 2: craft 4 planks from 1 log
        craft({'wooden_button':1}, {'planks':1}, null); # step 3: craft 1 wooden_button from 1 planks
        return "wooden_button"
    Descriptor: I succeed in step 1, 2, 3.
    User: Good. I finish all steps and I obtain 1 stone_pickaxe successfully.
    Planner: OK.

    ==========
    User: How to obtain 1 stone_sword in Minecraft step-by-step?
    Planner: The code for obtaining stone_sword is as follows:
    def obtain_1_stone_sword(inventory = {}):
        mine({'log':3}, null); # step 1: mine 3 log without tool
        craft({'planks':12}, {'log':3}, null); # step 2: craft 12 planks from 3 log
        craft({'stick':4}, {'planks':2}, null); # step 3: craft 4 stick from 2 planks
        mine({'cobblestone':2}, null); # step 4: mine 2 cobblestone without tool
        craft({'stone_sword':1}, {'cobblestone':2, 'stick':1}, 'crafting_table'); # step 5: craft 1 stone_sword from 2 cobblestone and 1 stick, on crafting_table
        return 'stone_sword'

    Descriptor: I succeed on step 1, 2, 3, but I fail on step 4 "mine({'cobblestone':2}, null);".  My inventory now has 10 planks, 4 stick.
    Explainer: Because mining cobblestone needs to use the tool wooden_pickaxe.
    User: Please fix the above errors and replan the task "obtain 1 stone_sword".
    RePlanner: The code for crafting stone_sword is as bellows:
    def obtain_1_stone_sword(inventory = {'planks':10, 'stick':4}):
        craft({'wooden_pickaxe':1}, {'planks':3, 'stick':2}, 'crafting_table');  # step 1: craft 1 wooden_pickaxe from 3 planks and 2 stick, on crafting_table
        mine({'cobblestone':2}, 'wooden_pickaxe'); # step 2: mine 2 cobblestone with wooden_pickaxe
        craft({'stone_sword':1}, {'cobblestone':2, 'stick':1}, 'crafting_table'); # step 3:  craft 1 stone_sword from 2 cobblestone and 1 stick, on crafting_table
        return 'stone_sword'

    Descriptor: I fail on step 1 "craft({'wooden_pickaxe':1}, {'planks':3, 'stick':2}, 'crafting_table');". My inventory now has 10 planks, 4 stick.
    Explainer: Because the action needs to use the tool crafting_table, but I do not have it.
    User: Please fix the above errors and replan the task "obtain 1 stone_sword".
    RePlanner: The code for crafting stone_sword is as bellows:
    def obtain_1_stone_sword(inventory = {'planks':10, 'stick':4}):
        craft({'crafting_table':1}, {'planks':4}, null); # step 1: craft 1 crafting_table from 4 planks
        craft({'wooden_pickaxe':1}, {'planks':3, 'stick':2}, 'crafting_table'); # step 2: craft 1 wooden_pickaxe from 3 planks and 2 stick, on crafting_table
        mine({'cobblestone':2}, 'wooden_pickaxe'); # step 3: mine 2 cobblestone with wooden_pickaxe
        craft({'stone_sword':1}, {'cobblestone':2, 'stick':2}, 'crafting_table'); # step 4: craft 1 stone_sword from 2 cobblestone and 1 stick, on crafting_table
        return 'stone_sword'
    Descriptor: I succeed in step 1, 2, 3, 4.
    User: Good. I finish all steps and I obtain 1 stone_pickaxe successfully.
    Planner: OK.

### Baselines

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    User: How to obtain 1 wooden_button in Minecraft step-by-step?
    Planner: The plan is as follows:
    step 1: mine 1 log
    step 2: craft 4 planks
    step 3: craft 1 wooden_button
    ###

    User: How to obtain stone_sword in Minecraft step-by-step?
    Planner: The plan is as follows:
    step 1: mine 3 log
    step 2: craft 12 planks
    step 3: craft 4 stick
    step 4: craft 1 crafting_table
    step 5: craft 1 wooden_pickaxe
    step 6: mine 2 cobblestone
    step 7: craft 1 stone_sword
    ###

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    User: How to obtain 1 wooden_button in Minecraft step-by-step?
    Planner: The code for obtaining wooden_button is as follows:
    '''
    from actions import mine_log, craft_planks, craft_wooden_button
    def obtain_wooden_button(inventory = {}):
        mine_log(num = 1); # step 1: mine 1 log
        craft_planks(num = 4); # step 2: craft 4 planks
        craft_wooden_button(num = 1); # step 3: craft 1 wooden_button
        return "wooden_button"
    '''


    User: How to obtain 1 stone_sword in Minecraft step-by-step?
    Planner: The code for obtaining stone_sword is as follows:
    '''
    from actions import mine_log, craft_planks, craft_stick, craft_crafting_table, craft_wooden_pickaxe, mine_cobblestone, craft_stone_sword

    def obtain_stone_sword(inventory = {}):
        mine_log(num = 3); # step 1: mine 3 log
        craft_planks(num = 12); # step 2: craft 12 planks
        craft_stick(num = 4); # step 3: craft 4 stick
        craft_crafting_table(num = 1); # step 4: craft 1 crafting_table
        craft_wooden_pickaxe(num = 1); # step 5: craft 1 wooden_pickaxe
        mine_cobblestone(num = 2); # step 6: mine 2 cobblestone
        craft_stone_sword(num = 1); # step 7: craft 1 stone_sword
        return "stone_sword"
    '''

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    User: How to obtain 1 wooden_button in Minecraft step-by-step?
    Planner: The plan is as follows:
    step 1: mine 1 log without tool
    Thinking: Inventory will add 1 log, as inventory = 1*log
    step 2: craft 4 planks from 1 log
    Thinking: Inventory will add 4 planks and delete 1 log, as inventory = 4*planks
    step 3: craft 1 wooden_button from 1 planks
    Thinking: Inventory will add 1 wooden_button and delete 1 planks, as inventory = 3*planks + 1*wooden_button
    ###

    User: How to obtain stone_sword in Minecraft step-by-step?
    Planner: The plan is as follows:
    step 1: mine 3 log without tool
    Thinking: Inventory will add 3 log, as inventory = 3*log.
    step 2: craft 12 planks from 3 log
    Thinking: Inventory will add 12 planks and delete 3 log, as inventory = 12*planks
    step 3: craft 4 stick from 2 planks
    Thinking: Inventory will add 4 stick and delete 2 planks, as inventory = 10*planks + 4*stick
    step 4: craft 1 crafting_table from 4 planks
    Thinking: Inventory will add 1 crafting_table and delete 4 planks, as inventory = 6*planks + 4*stick + 1*crafting_table
    step 5: craft 1 wooden_pickaxe from 3 planks and stick, on crafting_table
    Thinking: Inventory will add 1 wooden_pickaxe, delete 3 planks and delete 2 stick, as inventory = 3*planks + 2*stick + 1*crafting_table + 1*wooden_pickaxe
    step 6: mine 2 cobblestone with wooden_pickaxe
    Thinking: Inventory will add 2 cobblestone, as inventory = 3*planks + 2*stick + 1*crafting_table + 1*wooden_pickaxe + 2*cobblestone
    step 7: craft 1 stone_sword from 2 cobblestone and 1 stick, on crafting_table
    Thinking: Inventory will add 1 stone_sword, delete 2 cobblestone, and delete 1 stick, as inventory = 3*planks + 1*stick + 1*crafting_table + 1*wooden_pickaxe +  1*stone_sword
    ###

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    ===============
    User: Obtain 1 wooden_button in Minecraft step-by-step.

    Scene: My inventory has nothing.
    Planner: mine 1 log
    Robot Thought: mining log needs no tool
    Successful Action: True

    Scene: My inventory has 1 log.
    Planner: craft 4 planks
    Robot Thought: crafting 4 planks needs 1 log
    Successful Action: True

    Scene: My inventory has 4 planks
    Planner: craft 1 wooden_button
    {Robot Thought}: crafting 1 wooden_button needs 1 planks
    Successful Action: True

    ===============
    User: Obtain 1 stone_sword in Minecraft step-by-step.

    Scene: My inventory has nothing.
    Planner: mine 3 log
    Robot Thought: mining log needs no tool
    Successful Action: True

    Scene: My inventory has 3 log.
    Planner: craft 12 planks
    Robot Thought: crafting 12 planks needs 3 log
    Successful Action: True

    Scene: My inventory has 12 planks
    Planner: craft 4 stick
    Robot Thought: crafting 4 stick needs 2 planks
    Successful Action: True

    Scene: My inventory has 10 planks, 4 stick
    Planner: craft 1 wooden_pickaxe
    Robot Thought: crafting 1 wooden_pickaxe needs 3 planks and 2 stick on crafting_table
    Successful Action: False

    Scene: My inventory has 10 planks, 4 stick
    Planner: craft 1 crafting_table
    Robot Thought: crafting 1 crafting_table needs 4 planks
    Successful Action: True

    Scene: My inventory has 6 planks, 4 stick, 1 crafting_table
    Planner: craft 1 wooden_pickaxe
    Robot Thought: crafting 1 wooden_pickaxe needs 3 planks and 2 stick, on crafting_table
    Successful Action: True

    Scene: My inventory has 3 planks, 2 stick, 1 crafting_table, 1 wooden_pickaxe
    Planner: mine 2 cobblestone
    Robot Thought: mining cobblestone needs wooden_pickaxe as tool
    Successful Action: True

    Scene: My inventory has 3 planks, 2 stick, 1 crafting_table, 1 wooden_pickaxe, 2 cobblestone
    Planner: craft 1 stone_sword
    Robot Thought: crafting 1 stone_sword needs 2 cobblestone and 1 stick, on crafting_table
    Successful Action: True

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.

    User: How to obtain 1 wooden_button in Minecraft step-by-step?
    Planner: The code for obtaining wooden_button is as follows:
    def craft_stone_sword(inventory = {}):
        # step 1: mine 1 log without tool
        while not inventory.has({'log':1}):
            mine(obj = "log", tool = null);
        # step 2: craft 4 planks from 1 log
        while not inventory.has({'planks':4}):
            assert inventory.has({'log':1}), "I do not have enough log for crafting planks"
            craft(obj = "planks", tool = null);
        # step 3: craft 1 wooden_button from 1 planks
        while not inventory.has({'wooden_button':1}):
            assert inventory.has({'planks':1}), "I do not have enough planks for crafting wooden_button"
            craft(obj = "wooden_button", tool = null);
        return "wooden_button"
    ####

    User: How to obtain 1 stone_sword in Minecraft step-by-step?
    Planner: The code for obtaining stone_sword is as follows:
    def craft_stone_sword(inventory = {}):
        # step 1: mine 3 log without tool
        while not inventory.has({'log':3}):
            mine(obj = "log", tool = null);
        # step 2: craft 12 planks from 3 log
        while not inventory.has({'planks':12}):
            assert inventory.has({'log':1}), "I do not have enough log for crafting planks"
            craft(obj = "planks", tool = null);
        # step 3: craft 4 stick from 2 planks
        while not inventory.has({'stick':4}):
            assert inventory.has({'planks':2}), "I do not have enough planks for crafting stick"
            craft(obj = "stick", tool = null);
        # step 4: craft 1 crafting_table from 4 planks
        while not inventory.has({'crafting_table':1}):
            assert inventory.has({'planks':4}), "I do not have enough planks for crafting crafting_table"
            craft(obj = "crafting_table", tool = null)
        # step 5: craft 1 wooden_pickaxe from 3 planks and 2 stick, on crafting_table
        while not inventory.has({'wooden_pickaxe':1}):
            assert inventory.has({'planks':3}), "I do not have enough planks for crafting wooden_pickaxe"
            assert inventory.has({'stick':2}), "I do not have enough stick for crafting wooden_pickaxe"
            assert inventory.has({'crafting_table':1}), "I do not have the tool crafting_table for crafting wooden_pickaxe"
            craft(obj = "crafting_table", tool = "crafting_table")
        # step 6: mine 2 cobblestone with tool wooden_pickaxe
        while not inventory.has({'cobblestone':2}):
            assert inventory.has({'wooden_pickaxe':1}), "I do not have the tool wooden_pickaxe for mining cobblestone"
            mine(obj = "cobblestone", tool = "wooden_pickaxe")
        # step 7: craft 1 stone_sword from 2 cobblestone and 1 stick on crafting_table
        while not inventory.has({'stone_sword':1}):
            assert inventory.has({'cobblestone':2}), "I do not have enough cobblestone for crafting stone_sword"
            assert inventory.has({'stick':1}), "I do not have enough stick for crafting stone_sword"
            assert inventory.has({'crafting_table':1}), "I do not have the tool crafting_table for crafting wooden_pickaxe"
            craft(obj = "stone_sword", tool = "crafting_table")
        return "stone_sword"
    ####

## Prompt for ALFWorld Tasks {#sec:alfworld_prompt}

### DEPS

     % [language=python]

    Human: -= Welcome to TextWorld, ALFRED! =-
    Descriptor: You are in the middle of a room. Looking quickly around you, you see a cabinet 1, a diningtable 1 and a fridge 1.
    Human: Your task is to: put a cool tomato in cabinet. Please generate the sequences of sub-goals to complete the task.
    Planner: The task is to put a cool tomato in cabinet. The plan is below:
        #1 pick a tomato at fridge 1
        #2 cool a tomato at fridge 1
        #3 Put a tomato in cabinet at cabinet 1
    Descriptor: I fail on step 1 pick a tomato at fridge 1. I'm not carrying a tomato and there is no tomato, so the goal can't be accomplished.
    Explainer: It's probably because there isn't a tomato at fridge 1. The task is to put a cool tomato in cabinet. So I should pick a tomato somewhere else. I'm most likely to pick a tomato at diningtable 1.
    Planner: So the new plan is below:
        #1 pick a tomato at diningtable 1
        #2 put a tomato in cabinet at cabinet 1
    Descriptor: I succeed on step 1.
    Descriptor: I failed on step 2 put a tomato in cabinet at cabinet 1. I put a tomato in cabinet, but tomato 2 may not be a cool tomato, so the goal is not accomplished.
    Explainer: It's probably because the tomato isn't cool enough. The task is to put a cool tomato in cabinet. So I should cool the tomato. I'm most likely to cool a tomato at fridge 1.
    Planner: So the new plan is below:
        #2 cool a tomato at fridge 1
        #3 put a tomato in cabinet at cabinet 1
    Descriptor: I succeed on step 2.
    Descriptor: I succeed on step 3. I finish the task!!!

    Human:-= Welcome to TextWorld, ALFRED! =-
    Descriptor: You are in the middle of a room. Looking quickly around you, you see a desk 1, and a shelf 1.
    Human: Your task is to: look at mug under the desklamp. Please generate the sequences of sub-goals to complete the task.
    Planner: The task is to look at mug under the desklamp. The plan is below:
        #1 pick up a mug at shelf 1
        #2 use the desklamp at desk 1
    Descriptor: I succeed on step 1.
    Descriptor: I succeed on step 2. I finish the task!!!

     % [language=python]

    Human: You are in the middle of a room. You are not carrying anything. Your goal is to: pick a plate at diningtable 1.
    The 5 admissible actions of the current situation are :
    1. go to cabinet 1
    2. go to diningtable 1
    3. go to fridge 1
    4. inventory
    5. look
    AI: The goal is to pick a plate at diningtable 1. I'm not at diningtable 1. So I should go to diningtable 1 first. So the answer is 2.
    Human: You arrive at loc 17. On the diningtable 1, you see a plate 2, and a tomato 2.
    The 7 admissible actions of the current situation are :
    1. examine diningtable 1
    2. go to cabinet 1
    3. go to fridge 1
    4. inventory
    5. look
    6. take plate 2 from diningtable 1
    7. take tomato 2 from diningtable 1
    AI: The goal is to pick a plate at diningtable 1. I'm at diningtable 1, and there is a plate 2. So I should take plate 2 from diningtable 1. So the answer is 6.
    Human: You pick up the plate 2 from the diningtable 1.
    The 6 admissible actions of the current situation are :
    1. examine diningtable 1
    2. go to cabinet 1
    3. go to fridge 1
    4. inventory
    5. look
    6. put plate 2 in/on diningtable 1
    AI: The goal is to pick a plate at diningtable 1. According to Human, I pick up the plate 2 from diningtable 1. So the goal is accomplished.

    Human: You are facing fridge 1. You are carrying plate 2. Your goal is to: cool a plate at fridge 1.
    The 6 admissible actions of the current situation are :
    1. examine fridge 1
    2. go to cabinet 1
    3. go to diningtable 1
    4. inventory
    5. look
    6. cool plate 2 with fridge 1
    AI: The goal is to cool a plate at fridge 1. I'm at fridge 1. So I should cool plate 2 with fridge 1. So the answer is 6.
    Human: You cool the plate 2 using the fridge 1.
    The 5 admissible actions of the current situation are :
    1. examine fridge 1
    2. go to cabinet 1
    3. go to diningtable 1
    4. inventory
    5. look
    AI: The goal is to cool a plate at fridge 1. According to Human, I cool the plate 2 using the fridge 1. So the goal is accomplished.

    Human: You are facing diningtable 1. You are not carrying anything. Your goal is to: pick a plate at diningtable 1.
    The 6 admissible actions of the current situation are :
    1. examine diningtable 1
    2. go to cabinet 1
    3. go to fridge 1
    4. inventory
    5. look
    6. take tomato 2 from diningtable 1
    AI: The goal is to pick a plate at diningtable 1. I'm at diningtable 1, but there is no action to pick a plate. So the answer is 0(none). So the goal can't be accomplished, probably because there is no plate at diningtable 1.

    Human: You are facing fridge 1. You are not carrying anything. Your goal is to: cool a plate at fridge 1.
    The 5 admissible actions of the current situation are :
    1. examine fridge 1
    2. go to cabinet 1
    3. go to diningtable 1
    4. inventory
    5. look
    AI: The goal is to cool a plate at fridge 1. I'm at fridge 1, but there is no action to cool a plate. So the answer is 0(none). So the goal can't be accomplished, probably because I'm not carrying a plate.

    Human: You are facing fridge 1. You are carrying a plate. Your goal is to: pick a tomato at fridge 1.
    The 5 admissible actions of the current situation are :
    1. examine fridge 1
    2. go to cabinet 1
    3. go to diningtable 1
    4. inventory
    5. look
    AI: The goal is to pick a tomato at fridge 1. I'm at fridge 1, but there is no action to pick a tomato. So the answer is 0(none). So the goal can't be accomplished, probably because I can't pick a tomato while carrying a plate.

### Baselines

     % [language=python]

    Human: -= Welcome to TextWorld, ALFRED! =-
    Your task is to: cool some plate and put it in cabinet.
    Scene: You are in the middle of a room. Looking quickly around you, you see a cabinet 1, a diningtable 1 and a fridge 1.
    The 5 admissible actions of the current situation are :
    1. go to cabinet 1
    2. go to diningtable 1
    3. go to fridge 1
    4. inventory
    5. look
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying nothing. So I need to find a plate first. There are cabinet, diningtable and fridge, but no plate. I'm most likely to find a plate near diningtable. So I should go to diningtable 1. So the answer is 2.
    Robot Action: go to diningtable 1

    Scene: You arrive at loc 17. On the diningtable 1, you see a plate 2, and a tomato 2.
    The 7 admissible actions of the current situation are :
    1. examine diningtable 1
    2. go to cabinet 1
    3. go to fridge 1
    4. inventory
    5. look
    6. take plate 2 from diningtable 1
    7. take tomato 2 from diningtable 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying nothing. So I need to find a plate first. There is a plate 2. So I should take plate 2 from diningtable 1. So the answer is 6.
    Robot Action: take plate 2 from diningtable 1

    Scene: You pick up the plate 2 from the diningtable 1.
    The 7 admissible actions of the current situation are :
    1. examine diningtable 1
    2. examine plate 2
    3. go to cabinet 1
    4. go to fridge 1
    5. inventory
    6. look
    7. put plate 2 in/on diningtable 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying a plate 2. So I need to cool a plate first. There are cabinet, diningtable, and fridge. I'm most likely to cool a plate near fridge. So I should go to fridge 1. So the answer is 4.
    Robot Action: go to fridge 1

    Scene: You arrive at loc 41. The fridge 1 is closed.
    The 8 admissible actions of the current situation are :
    1. cool plate 2 with fridge 1
    2. examine fridge 1
    3. examine plate 2
    4. go to cabinet 1
    5. go to diningtable 1
    6. inventory
    7. look
    8. open fridge 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying a plate 2. So I need to cool a plate first. There is a fridge 1. So I should cool plate 2 with fridge 1. So the answer is 1.
    Robot Action: cool plate 2 with fridge 1

    Scene: You cool the plate 2 using the fridge 1.
    The 8 admissible actions of the current situation are :
    1. cool plate 2 with fridge 1
    2. examine fridge 1
    3. examine plate 2
    4. go to cabinet 1
    5. go to diningtable 1
    6. inventory
    7. look
    8. open fridge 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying a cool plate 2. So I need to find a cabinet first. There is a cabinet 1. So I should go to cabinet 1. So the answer is 4.
    Robot Action: go to cabinet 1

    Scene: You arrive at loc 20. The cabinet 1 is closed.
    The 7 admissible actions of the current situation are :
    1. examine cabinet 1
    2. examine plate 2
    3. go to diningtable 1
    4. go to fridge 1
    5. inventory
    6. look
    7. open cabinet 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying a cool plate 2. So I need to find a cabinet first. There is a cabinet 1. The cabinet is closed. So I should open cabinet 1. So the answer is 7.
    Robot Action: open cabinet 1

    Scene: You open the cabinet 1. The cabinet 1 is open. In it, you see nothing.
    The 8 admissible actions of the current situation are :
    1. close cabinet 1
    2. examine cabinet 1
    3. examine plate 2
    4. go to diningtable 1
    5. go to fridge 1
    6. inventory
    7. look
    8. put plate 2 in/on cabinet 1
    Robot Thought: The task is to cool some plate and put it in cabinet. I'm carrying a cool plate 2. So I need to find a cabinet first. There is a cabinet 1. So I should put plate 2 in/on cabinet 1. So the answer is 8.
    Robot Action: put plate 2 in/on cabinet 1

    Scene: You put the plate 2 in/on the cabinet 1. You won!!!

## Prompt for Tabletop Manipulation Tasks {#sec:tabletop_prompt}

### DEPS

     % [language=python]

    system: The template of the lang goal is as follow: put the <color> blocks in a <color> bowl. For example, "put the green blocks in a blue bowl" is a valid lang goal. Do not provide any additional explanations or instructions beyond writing lang goals.

    user: There are 4 bowls of blue, green, pink, yellow on the table. There are 3 blocks of red, yellow, blue on the table. How to match the blocks and the bowls?

    assistant:
    1. put the yellow blocks in a yellow bowl
    2. put the blue blocks in a blue bowl

### Baselines

     % [language=python]

    system: The template of the language goal is as follows: put the <color> blocks in a <color> bowl. For example, "put the green blocks in a blue bowl" is a valid lang goal. Do not provide any additional explanations or instructions beyond writing lang goals and determing the game is DONE. Please write a single lang goal in your response!

    user: There are 4 bowls of blue, green, pink, yellow on the table. There are 3 blocks of red, yellow, blue on the table. What should I do as the first step to match the blocks with the bowls of the literally same color? Note that not all the blocks can be matched and you can determine the game is DONE anywhere.
    assistant: put the yellow blocks in a yellow bowl

    user: OK. What should I do next?
    assistant: put the blue blocks in a blue bowl

    user: OK. I finish the task!

# Full Dialogue {#sec:interaction}

     % [language=python]

    User: You are a helper agent in Minecraft. You need to generate the sequences of goals for a certain task in Minecraft.
    Planner: OK.
    ======================================
    User: How to obtain 1 diamond in Minecraft step-by-step?
    Planner: The code for task obtaining diamond is as bellows:
    def obtain_1_diamond(inventory = {}):
        mine({'log':3}, null); # step 1: mine 3 log without tool
        craft({'planks':12}, {'log':3}, null); # step 2: craft 12 planks from 3 log
        craft({'stick':4}, {'planks':2}, null); # step 3: craft 4 stick from 2 planks
        craft({'crafting_table':1}, {'planks':4}, null); # step 4: craft 1 crafting_table from 4 planks
        craft({'wooden_pickaxe':1}, {'planks':3, 'stick':2}, 'crafting_table'); # step 5: craft 1 wooden_pickaxe from 3 planks and 2 stick, on crafting_table
        mine({'cobblestone':2}, 'wooden_pickaxe'); # step 6: mine 2 cobblestone with wooden_pickaxe
        craft({'stone_pickaxe':1}, {'cobblestone':3, 'stick':2}, 'crafting_table'); # step 7: craft 1 stone_pickaxe from 3 cobblestone and 2 stick, on crafting_table
        mine({'diamond':1}, 'stone_pickaxe'); # step 8: mine 1 diamond with stone_pickaxe
        return 'diamond'

    Descriptor: I succeed on step 1, 2, 3, 4, 5, 6, but I fail on step 7 "craft({'stone_pickaxe':1}, {'cobblestone':3, 'stick':2}, 'crafting_table');". My inventory now has 7 planks, 2 stick, 1 crafting_table, 1 wooden_pickaxe, 2 cobblestone, 5 dirt.
    Explainer: Because crafting stone_pickaxe needs 3 cobblestone, but I only have 2 cobblestone in inventory.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for task obtaining 1 diamond is as follows:
    def obtain_1_diamond(inventory = {'planks':7, 'stick':2, 'crafting_table':1, 'wooden_pickaxe':1, 'cobblestone':2, 'dirt':5}):
        mine({'cobblestone':1}, 'wooden_pickaxe'); # step 1: mine 1 cobblestone with wooden_pickaxe
        craft({'stone_pickaxe':1}, {'cobblestone':3, 'stick':2}, 'crafting_table'); # step 2: craft 1 stone_pickaxe from 3 cobblestone and 2 stick, on crafting_table
        mine({'diamond':1}, 'stone_pickaxe'); # step 3: mine 1 diamond with stone_pickaxe
        return 'diamond'

    Descriptor: I succeed on step 1, 2 in new plan, but I fail on step 3 "mine({'diamond':1}, 'stone_pickaxe');". My inventory now has 7 planks, 1 crafting_table, 1 wooden_pickaxe, 1 cobblestone, 5 dirt, 1 stone_pickaxe.
    Explainer: Because mining diamond needs to use the tool iron_pickaxe, but I do not have it.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def obtain_1_diamond(inventory = {'planks':7, 'crafting_table':1, 'wooden_pickaxe':1, 'cobblestone':1, 'dirt':5, 'stone_pickaxe':1}):
        mine({'iron_ore':1}, 'stone_pickaxe'); # step 1: mine 1 iron_ore with stone_pickaxe
        smelt({'iron_ingot':1}, {'iron_ore':1}, 'furnace'); # step 2: craft 1 iron_ingot from 1 iron_ore, on furnace
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # step 3: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # step 4: mine 1 diamond with iron_pickaxe
        return 'diamond'

    Descriptor: I success on step 1 in new plan, but I fail on step 2 "smelt({'iron_ingot':1}, {'iron_ore':1}, 'furnace');". My inventory now has 7 planks, 1 crafting_table, 1 wooden_pickaxe, 6 cobblestone, 1 iron_ore, 20 dirt, 64 stone.
    Explainer: Because smelting iron ingot needs to use the tool furnace, but I do not have it.
    User: Please fix above errors and replan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def mine_1_diamond(inventory = {'planks':7, 'crafting_table':1, 'wooden_pickaxe':1, 'cobblestone':6, 'iron_ore':1, 'dirt':20, 'stone':64}):
        craft({'furnace':1}, {'cobblestone':8}, null); # step 1: craft 1 furnace from 8 cobblestone
        craft({'iron_ingot':1}, {'iron_ore':1}, 'furnace'); # step 2: craft 1 iron_ingot from 1 iron_ore, on furnace
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # step 3: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # step 4: mine 1 diamond with iron_pickaxe
        return 'diamond'

    Descriptor: I fail on step 1 "craft({'furnace':1}, {'cobblestone':8}, null);". My inventory now has 7 planks, 1 crafting_table, 1 wooden_pickaxe, 6 cobblestone, 1 iron_ore, 20 dirt, 64 stone.
    Explainer: Because crafting furnace needs 8 cobblestone, but I only have 6 cobblestone.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def obtain_1_diamond(inventory = {'planks':7, 'crafting_table':1, 'wooden_pickaxe':1, 'cobblestone':6, 'iron_ore':1, 'dirt':20, 'stone':64}):
        mine({'cobblestone':8}, 'stone_pickaxe'); # step 1: mine 8 cobblestone with stone_pickaxe
        craft({'furnace':1}, {'cobblestone':8}, null); # step 2: craft 1 furnace from 8 cobblestone
        smelt({'iron_ingot':1}, {'iron_ore':1}, 'furnace'); # step 3: craft 1 iron_ingot from 1 iron_ore, on furnace
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # step 4: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # step 5: mine 1 diamond with iron_pickaxe
        return 'diamond'

    Descriptor: I succeed on step 1 in new plan, but I fail on step 2 "craft({'furnace':1}, {'cobblestone':8}, null);". My inventory now has 7 planks, 1 crafting_table, 1 wooden_pickaxe, 1 stone_pickaxe, 8 cobblestone, 1 iron_ore, 20 dirt, 64 stone.
    Explainer: Because crafting furnace needs to use the tool crafting_table, but I do not have it.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def obtain_1_diamond(inventory = {'planks':7, 'crafting_table':1, 'wooden_pickaxe':1, 'cobblestone':8, 'iron_ore':1, 'dirt':20, 'stone':64}):
        craft({'furnace':1}, {'cobblestone':8}, 'crafting_table'); # step 1: craft 1 furnace from 8 cobblestone, on crafting_table
        smelt({'iron_ingot':1}, {'iron_ore':1}, 'furnace'); # step 2: smelt 1 iron_ingot from 1 iron_ore, on furnace
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # step 3: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # step 4: mine 1 diamond with iron_pickaxe
        return 'diamond'

    Descriptor: I succeed on step 1, 2 in new plan, but I fail on step 3 "craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table');". My inventory now has 6 planks, 1 crafting_table, 1 wooden_pickaxe, 1 stone_pickaxe, 1 furnace, 1 iron_ingot, 20 dirt, 64 stone.
    Explainer: Because crafting iron pickaxe needs 3 iron_ingot, but I only have 1 iron_ingot.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def mine_1_diamond(inventory = {'planks':6, 'crafting_table':1, 'wooden_pickaxe':1, 'stone_pickaxe':1, 'furnace':1, 'iron_ingot':1, 'dirt':20, 'stone':64}):
        mine({'iron_ore':2}, 'stone_pickaxe'); # action 1: mine 2 iron_ore with stone_pickaxe
        smelt({'iron_ingot':2}, {'iron_ore':2}, 'furnace'); # action 2: craft 2 iron_ingot from 2 iron_ore, on furnace
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # action 3: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # action 4: mine 1 diamond with iron_pickaxe
        return 'diamond'

    Descriptor: I succeed on step 1, 2 in new plan, but I fail on step 3 "craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table');". My inventory now has 5 planks, 1 crafting_table, 1 wooden_pickaxe, 1 stone_pickaxe, 1 furnace, 3 iron_ingot, 20 dirt, 64 stone.
    Explainer: Because crafting iron_pickaxe needs 2 stick, but I do not have it.
    User: Please fix above errors and re-plan the task "obtain 1 diamond".
    RePlanner: The code for obtaining 1 diamond is as follows:
    def obtain_1_diamond(inventory = {'planks':5, 'crafting_table':1, 'wooden_pickaxe':1, 'stone_pickaxe':1, 'furnace':1, 'iron_ingot':3, 'dirt':20, 'stone':64}):
        craft({'stick':2}, {'planks':1}, null); # action 15: craft 2 stick from 1 planks
        craft({'iron_pickaxe':1}, {'iron_ingot':3, 'stick':2}, 'crafting_table'); # action 16: craft 1 iron_pickaxe from 3 iron_ingot and 2 stick, on crafting_table
        mine({'diamond':1}, 'iron_pickaxe'); # action 17: mine 1 diamond with iron_pickaxe
        return 'diamond'
    Descriptor: I succeed in step 1, 2, 3.
    User: Good. I finish all steps and I obtain 1 stone_pickaxe successfully.
    Planner: OK.






