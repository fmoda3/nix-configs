# Abstract {#abstract .unnumbered}

Large language models' reasoning abilities benefit from methods that organize their thought processes, such as chain-of-thought prompting, which employs a sequential structure to guide the reasoning process step-by-step. However, existing approaches focus primarily on organizing the sequence of thoughts, leaving structure in individual thought steps underexplored. To address this gap, we propose Table as Thought, a framework inspired by cognitive neuroscience theories on human thought. Table as Thought organizes reasoning within a tabular schema, where rows represent sequential thought steps and columns capture critical constraints and contextual information to enhance reasoning. The reasoning process iteratively populates the table until self-verification ensures completeness and correctness. Our experiments show that Table as Thought excels in planning tasks and demonstrates a strong potential for enhancing LLM performance in mathematical reasoning compared to unstructured thought baselines. This work provides a novel exploration of refining thought representation within LLMs, paving the way for advancements in reasoning and AI cognition.

# Introduction

Recent advancements in reasoning have demonstrated that the reasoning capabilities of large language models (LLMs) can be enhanced by introducing structure into the reasoning process [wei2023chainofthoughtpromptingelicitsreasoning; yao2023treethoughtsdeliberateproblem; besta2024got]. For instance, the chain-of-thought approach organizes textual reasoning in a step-by-step manner using a linear chain structure [wei2023chainofthoughtpromptingelicitsreasoning]. Building on this, following works have shown that incorporating more complex organizational structures further improves reasoning performance [besta2024got; yao2023treethoughtsdeliberateproblem]. However, these approaches structure reasoning only at the level of connections between distinct reasoning steps (inter-thought level) and leave the content of individual steps (thought level) unstructured. This raises the critical question: **_Can LLMs' reasoning abilities be further enhanced by introducing structure within individual thoughts?_**

To address this question, we draw inspiration from cognitive neuroscience theories of human thought. Neuroscientists have found that humans think in a structured way, with the brain's organization facilitating sequential and goal-oriented reasoning. [Christoff2000] provided early evidence that the prefrontal cortex supports structured reasoning through a rostrocaudal hierarchy, enabling the processing of increasingly abstract concepts and complex goal-directed behavior. Later, [Friston2005]'s predictive coding framework demonstrated how structured cognition emerges from the brain's ability to build hierarchical models, combining experiences with current input to predict results. More recently, Jeff Hawkins [Hawkins2021] argued that humans think in a structured manner, with the neocortex organizing knowledge in certain structures, and thinking arises from neurons activating sequential locations in these frames. Building on these insights, we propose investigating whether similarly structured representations can be incorporated into LLMs to enhance their reasoning and planning capabilities.

In this work, we adopt a simple yet effective structural format---a tabular schema---to approximate the structured nature of human thinking processes. In our approach, the schema of a table serves as a framework for organizing and navigating knowledge. Inspired by the sequential processes described in neuroscience---where neurons activate specific patterns step by step [Hawkins2021]---we model these processes as the sequential population of rows in a table, moving across columns according to a predefined schema. A single table can encapsulate one or more such structured thought processes, providing a coherent container for organizing and connecting thinking steps and associated information. Tables not only represent step-by-step processes for achieving specific goals but also serve as robust frameworks for planning tasks. Moreover, utilizing tables as structured representations enables schema design that ensures organization and data integrity, thereby facilitating efficient verification and analysis.

The contributions of our paper are as follows:

- Motivated by insights from cognitive neuroscience regarding the structured nature of human thinking, we propose a novel framework, Table as Thought, that injects structure at the thought level. To the best of our knowledge, this is the first exploration and demonstration of integrating structured representations directly into the reasoning process of large language models.

- We demonstrate the advantages of Table as Thought in tasks requiring planning and mathematical reasoning, highlighting its potential to enhance performance on tasks that demand sequential and goal-oriented thought processes.

- We provide a detailed and comprehensive analysis of Table as Thought, offering insights into its functionality and strengths, and comparing the benefits of structured versus unstructured thought representations. We believe these findings can inspire future research into the nature and representation of thought processes in artificial intelligence and computational linguistics.

# Related Work

#### Structures in LLM Reasoning

Recent advancements in large language models (LLMs) have increasingly focused on integrating structured processes to enhance reasoning capabilities. Chain-of-Thought prompting [wei2023chainofthoughtpromptingelicitsreasoning] introduces a step-by-step framework that organizes thoughts in a sequential manner, enabling more coherent reasoning. Building on this, Tree of Thoughts [yao2023treethoughtsdeliberateproblem] and Graph of Thoughts [besta2024got] employ hierarchical and networked structures to further enhance problem-solving, leveraging branching and interconnected paths. Moreover, self-consistency [wang2023selfconsistencyimproveschainthought] improves reliability by sampling multiple reasoning paths and selecting the most consistent outcome, thereby addressing variability in generated responses.

While these methods excel at organizing reasoning at a macro level---such as through chaining, branching, or aggregating thought paths---they do not address the internal structure of individual thoughts. Our work is distinct in that it introduces structure directly at the thought level, refining the granularity of reasoning processes in LLMs. By focusing on the internal organization of individual reasoning steps, we provide a novel perspective on enhancing the depth and precision of structured reasoning in LLMs.

#### Representations of Tables in LLM Inference

Tables have traditionally played a significant role in LLMs for tasks involving the understanding and processing of tabular data, such as knowledge retrieval [cong2024observatorycharacterizingembeddingsrelational], question answering over structured data [yin-etal-2020-tabert; zhang2024tablellamaopenlargegeneralist], and tabular reasoning [herzig-etal-2020-tapas; deng-etal-2024-tables]. In these tasks, tables are leveraged only as input for interpretation and manipulation.

The Chain-of-Table framework [wang2024chainoftableevolvingtablesreasoning] extends the application of tables by employing them as proxies for intermediate thoughts in reasoning tasks involving tabular data. In this framework, LLMs iteratively update a table, forming a dynamic reasoning chain where the table evolves based on intermediate results. While this approach has proven effective on tabular-specific datasets, it remains inherently tied to tasks where tabular data is part of the input or reasoning context.

In contrast, our work redefines the role of tables by utilizing them as a universal framework for structuring and representing the internal thought processes of LLMs in non-table-specific tasks, such as planning and mathematical reasoning. Unlike prior approaches that depend on pre-existing tabular inputs, we employ tables as dynamic containers to organize and manipulate thoughts step by step. This approach enables structured reasoning even in tasks where no tabular data is initially present, bridging the gap between unstructured text-based reasoning and structured problem-solving paradigms. By generalizing the utility of tables beyond table-specific reasoning tasks, our work marks a significant departure from previous methods and demonstrates the versatility of this novel framework.

[IMAGE: Figure_1.pdf - The Overall Pipeline for Table as Thought Reasoning. The figure illustrates how Table as Thought structures reasoning by iteratively populating a reasoning table based on the schema, verifying consistency, and updating the table until the final answer is achieved.]

# Table as Thought

We present the design of the Table as Thought framework, which introduces a novel approach to reasoning in large language models by leveraging tables as structured representations of thoughts.

#### Table as Thought.

Table as Thought employs a table as a container to represent one or more structured thoughts. These tables, referred to as **\"reasoning tables\"**, encapsulate thoughts and provide a transparent representation of the reasoning process. A reasoning table $T$ is initialized with an original table schema $S$, which is defined by the LLM for a given query $Q$. Structured thoughts $\Theta$ are then generated based on $S$, with each thought corresponding to a row in the reasoning table $T$. The table $T$ is subsequently populated and updated according to these structured thoughts $\Theta$.

The overall reasoning workflow using the reasoning table is illustrated in Figure [1](#fig:table_as_thought) and formalized in Algorithm [\[alg:table_as_thought\]](#alg:table_as_thought).

```
Algorithm:
ic
Query $Q$ A table $T$ that satisfies $Q$
$S \gets \textsc{DesignSchema}(Q)$ // Define table schema Initialize an empty table $T$ with schema $S$. $\Theta \gets \textsc{Reflect}(T, Q)$ // Generate possible updates $T \gets \textsc{UpdateTable}(T, \Theta)$ // Apply updates if needed $T$
```

#### Schema Development Module

The Schema Development Module dynamically adapts table schemas to accommodate various queries across different reasoning tasks. For constraint-planning tasks, where the primary objective is to satisfy constraints, we prompt LLMs to identify the constraints explicitly before designing the schema. This ensures that both explicit and implicit constraints are addressed in the reasoning process. For mathematical reasoning tasks, the schema is tailored to reflect the logical progression of the reasoning steps, enabling systematic organization of critical information.

The headers in the table schemas are designed to represent essential reasoning steps and key information pertinent to the task. These headers act as anchors for organizing and verifying intermediate and final reasoning outputs.

For example, consider the travel planning query:

> `I plan to travel alone, and my planned budget for the trip is around $1,100.`

In this case, a key constraint is that the total cost should not exceed \$1,400. To address this constraint, the schema must include a header such as `Cost`, with the type `Number`, ensuring that the relevant information is captured and evaluated against the budgetary constraint.

For a mathematical reasoning task, such as a question from the GSM8K dataset:

> `A robe takes 2 bolts of blue fiber and half that much white fiber. How many bolts in total does it take?`

Here, the reasoning process requires consideration of the quantities of blue and white fibers. The schema should therefore include keys such as `Blue Fiber` and `White Fiber`, ensuring that all relevant elements are systematically tracked and calculated.

#### Reasoning Verification Module

The inclusion of this module stems from our findings during experiments that current LLMs sometimes fail to generate the complete reasoning process with structured thoughts to solve a query. However, this module is designed not only to verify the completeness of the reasoning process, but also to ensure its correctness.

For constraint reasoning tasks, the module guarantees that all necessary information required to meet the constraints defined in the schema is captured and satisfied. Specifically, it verifies whether the constraints identified during the schema development phase are adhered to. Constraint checking is generally performed internally by the LLM through reflective reasoning on the generated table, with constraints explicitly listed for verification. The structured nature of thoughts in Table as Thought introduces an additional capability: **Auto-Check Constraints**, which are constraints set for external verification, performed entirely by the system to ensure that the table adheres to the defined constraints. By leveraging the structured representations of Table as Thought, Auto-Check Constraints facilitate the systematic validation of intermediate steps and final outputs without relying on the LLM.

For mathematical reasoning tasks, the module evaluates the correctness of the reasoning process by ensuring that the table reflects an accurate and logical reasoning path toward solving the problem. This involves checking whether the intermediate and final outputs align with the expected reasoning steps outlined in the schema.

#### Table Construction Module

The Table Construction Module iteratively generates structured thoughts and constructs the reasoning table by incorporating the schema and feedback from the reasoning verification module. This process involves dynamically adding new thoughts to the table, modifying existing entries, or removing entries that do not align with the schema or query requirements.

The iterative process terminates under one of the following conditions:

1.  The reasoning table is verified as complete and correct by the reasoning verification module.

2.  The maximum number of iterations, which is 10 in all our experiments, is reached.

# Experiments

## Tasks and Language Models

For all tasks, we adopt the original evaluation methods to ensure consistency and comparability.

#### Constraint Planning Tasks.

The goal of constraint planning tasks is to generate plans that satisfy both explicit and implicit constraints. We evaluate our approach on two datasets, each presenting different levels of complexity in the expected plans. The TravelPlanner dataset [xie2024travelplannerbenchmarkrealworldplanning] requires LLMs to generate detailed travel plans that adhere to explicit constraints provided in the query, such as budget limitations, as well as implicit constraints derived from common sense. The expected travel plans are highly complex, encompassing multi-day agendas that include transportation, accommodations, and daily attractions. Due to the exceptionally long context required for this task, which results in substantial token costs, we conduct experiments exclusively with GPT-4-o-mini. The calendar scheduling task from the NaturalPlan benchmark [zheng2024naturalplanbenchmarkingllms] focuses on generating single-object plans. In this task, LLMs must determine an appropriate meeting time based on explicit constraints, such as the company's working hours and the unavailable time slots of each participant.

#### Math reasoning tasks.

We evaluate LLMs using GSM-8K and MATH500 to assess structured mathematical reasoning. GSM-8K [cobbe2021gsm8k] contains 8,000 grade-school-level word problems, testing multi-step reasoning and numerical precision. MATH500 [lightman2023letsverifystepstep] features 500 advanced problems from the MATH dataset [hendrycks2021measuringmathematicalproblemsolving], covering algebra, calculus, and geometry. It challenges models with tasks requiring symbolic manipulation and deep mathematical understanding. These datasets help evaluate our approach across diverse scenarios, from simple arithmetic to complex problems.

#### Language Models.

The schema design and table construction modules in Table as Thought require LLMs capable of generating complex, structured outputs that conform to intricate schemas. This capability is natively supported by OpenAI's Structured Outputs Mode, which allows for precise alignment with defined schema requirements. Consequently, our experiments are conducted exclusively on OpenAI's GPT-4-o-mini and GPT-4-o-2024-08-06 models [openai2024gpt4technicalreport]. Expanding the evaluation to include open-source models with similar capabilities remains an area for future work.

## Text Thought Baselines

#### Direct Prompting.

Direct Prompting involves solving queries by directly generating an answer from the input, without prompting for any intermediate reasoning steps.

#### CoT Prompting.

Chain-of-Thought (CoT) Prompting organizes reasoning as a sequential chain of thoughts, thereby injecting structure into the reasoning process.

#### Text as Thought.

This approach differs from Table as Thought only in its use of unstructured representations for thoughts. **Text as Thought** employs text as the medium for reasoning. This method extends CoT prompting by iteratively updating the reasoning process based on reflection. Each iteration involves generating intermediate reasoning steps, reflecting on their correctness, and refining the reasoning path as needed. The streamlined process is formalized in Algorithm [\[alg:text_as_thought\]](#alg:text_as_thought).

```
Algorithm:
ic
Query $Q$ A text $T$ that satisfies $Q$
Initialize an empty text $T$. $\Theta \gets \textsc{Reflect}(T, Q)$ // Generate possible updates $T \gets \textsc{UpdateText}(T, \Theta)$ // Apply updates if needed $T$
```

## Variations of Table as Thought

To fully explore and understand the boundaries of Table as Thought, we introduce two variations to the TravelPlanner task. These variations include Table as Thought with auto check constraint, which adds complexity to schema design, and Table as Thought with given schema, which simplifies the task by providing a predefined schema.

#### Table as Thought with Auto-Check Constraint.

This variation builds on the vanilla Table as Thought by requiring the LLM to add additional constraints during schema design to ensure data integrity and reflect the constraints present in the query. For instance, if a TravelPlanner query includes budget constraints, the LLM is expected to design a schema with headers like `Cost` and enforce a rule ensuring that the sum of the column does not exceed the specified budget. By introducing this variation, we aim to explore the boundaries of LLMs in designing complex reasoning structures and handling intricate schema requirements.

#### Table as Thought with Given Schema.

In this variation, the LLM is provided with a predefined schema, as shown in Table [\[tab:given_vs_LLM_schema\]](#tab:given_vs_LLM_schema), rather than designing the schema independently. The given schema is derived from the evaluation pipeline of the TravelPlanner task [xie2024travelplannerbenchmarkrealworldplanning], where answers are processed into tables following this schema before evaluation. This variation serves as a comparative baseline to assess the effectiveness and adaptability of schemas designed by LLMs compared to fixed, predefined schemas.

# Results

## Calendar Scheduling Task

Table as Thought achieves the highest performance among all prompting methods on the Calendar Scheduling Task, as shown in Table [\[tab:calendar_scheduling_results\]](#tab:calendar_scheduling_results). On GPT-4o, Table as Thought improves performance by 10.8% over Direct Prompting and achieves a 5.4% improvement compared to the Text as Thought baseline. This highlights the advantage of using tables as structured representations for planning over unstructured text-based representations. A similar trend is observed with GPT-4o-mini, where Table as Thought outperforms other methods, suggesting the robustness of table-based reasoning for simpler constraint reasoning tasks like calendar scheduling.

For GPT-4o, the improvement from Direct Prompting to CoT Prompting is minimal (0.5%), indicating that chain-like reasoning structures may already be embedded in the model's reasoning process. However, incorporating self-verification through Text as Thought yields a 4.9% improvement. Importantly, transitioning from unstructured thoughts to structured tables results in a more substantial performance boost (5.4%), underscoring the benefits of structured representations in reasoning tasks.

For GPT-4o-mini, a less advanced model, CoT Prompting achieves a moderate 2.2% improvement over Direct Prompting, but Text as Thought fails to provide any additional gains. This suggests that GPT-4o-mini lacks both the natural incorporation of chain-like structures in its reasoning and the self-verification capability to improve performance on text-based reasoning tasks. In contrast, Table as Thought demonstrates a significant 4.4% improvement over CoT Prompting, reinforcing the effectiveness of introducing structure at the thought level over chain-like structures at the reasoning level for less advanced models.

## TravelPlanner Task

Table [\[tab:travel_planner_transposed_split\]](#tab:travel_planner_transposed_split) shows that Table as Thought with a given schema achieves the best performance across most metrics in the TravelPlanner task, underscoring the potential of structured thoughts. The significant improvement from vanilla Table as Thought to Table as Thought with a given schema highlights that current LLMs struggle to design effective table schemas for achieving complex objectives. This limitation will be analyzed in more detail in the next section.

The results reveal an important trend: on a challenging task like TravelPlanner, which demands reasoning toward a complex objective, introducing increasingly sophisticated structures into the reasoning process can lead to performance degradation. Specifically, methods that incorporate additional complexity---such as chain-of-thought (CoT) prompting, self-reflection in Text as Thought, and rule-constrained structured thoughts in Table as Thought with Auto-Check constraint---tend to perform worse compared to simpler approaches. The exception is Table as Thought with a given schema, which avoids this degradation by relieving the LLM of the need to design its own schema, allowing it to focus solely on reasoning within a predefined structure.

## Math Reasoning Tasks

Table [\[tab:combined_results\]](#tab:combined_results) highlights a general trend in the MATH500 and GSM8K tasks: introducing additional complexity into the reasoning process often leads to a performance drop, particularly for less capable models like GPT-4o-mini. For instance, on MATH500, the performance of both GPT-4o and GPT-4o-mini decreases as the reasoning structures become more sophisticated, from Direct Prompting to Text as Thought to Table as Thought. This effect is especially pronounced for GPT-4o-mini, where the performance of Table as Thought falls to 47.8%, compared to 65.4% with Direct Prompting. A similar trend is observed on GSM8K, where the addition of more structured reasoning methods results in marginal performance degradation. These results suggest that LLMs may already be overfitted to math reasoning tasks, as noted in recent studies [mirzadeh2024gsmsymbolicunderstandinglimitationsmathematical; zhang2024carefulexaminationlargelanguage].

Despite this general trend, Table as Thought demonstrates its potential to improve performance by successfully solving questions that text-thought-based methods fail to address, particularly with more capable models like GPT-4o. Table [\[tab:table_sucess_text_failed_math\]](#tab:table_sucess_text_failed_math) provides a detailed breakdown of the percentage of questions that Table as Thought solves, which were missed by other methods. On MATH500, Table as Thought resolves approximately 20% of such questions, while on GSM8K, this figure exceeds 30%. These findings underscore the utility of structured reasoning in identifying alternative pathways to solutions that text-based reasoning methods may overlook.

# Analysis

## Effect of Schema Design on Reasoning Structures

Schema design plays a pivotal role in structuring the reasoning paths of Calendar Scheduling tasks. Different schemas determine the granularity of the reasoning process, which in turn affects model performance.

Table [\[tab:multi_one_schema\]](#tab:multi_one_schema) shows that in the **one-row schema**, the reasoning process is concise: the LLM identifies all available time slots for participants in a single step and selects a suitable meeting time. This schema produces a single-row table, encapsulating the reasoning process in a compact form. In contrast, the **multi-row schema** divides the process into finer-grained steps. The LLM first extracts unavailable and preferred time slots for each participant. It then computes available time slots before aggregating this information to finalize the meeting time. This approach results in a table with multiple rows, each representing an intermediate reasoning step, and provides a more detailed reasoning path.

Table [1](#tab:multi_vs_one) shows that schema complexity impacts performance differently for advanced and less capable models. For GPT-4o, the multi-row schema outperforms the one-row schema, achieving 80.28% accuracy compared to 72.93%. This suggests that the finer-grained reasoning path introduced by the multi-row schema aligns well with GPT-4o's stronger table reasoning capabilities. By explicitly structuring intermediate steps, the multi-row schema allows GPT-4o to better manage constraints and ensure reasoning correctness. On the contrary, GPT-4o-mini performs better with the simpler one-row schema (45.05% vs. 43.46% for the multi-row schema). This indicates that the increased complexity of the multi-row schema exceeds the model's table reasoning and verification abilities, leading to performance degradation.

               **GPT-4o-mini**   **GPT-4o**

---

One Row 45.05 72.93
Multi Row 43.46 80.28

: Performance Comparison of Multi Row and One Row Schemas for GPT-4o-mini and GPT-4o on Calendar Scheduling

## LLM Struggles to Design Effective Schema for Complex Planning

Unlike Calendar Scheduling, which focuses on selecting a single time slot, TravelPlanner involves generating a comprehensive travel itinerary, significantly increasing the complexity of the planning task. Our findings indicate that tasking the LLM with designing a table schema results in a notable performance drop compared to using direct prompting with a pre-defined schema. This suggests that LLMs currently lack the capability to independently design effective table schemas for complex planning tasks.

Although the provided schema is not perfect---omitting some critical columns, such as \"cost\" for budget constraints---it is generally more effective than most LLM-designed schemas. For instance, as shown in Table [\[tab:given_vs_LLM_schema\]](#tab:given_vs_LLM_schema), the LLM-developed schema and the given schema are structurally similar. However, a key difference is the use of \"Dining Options\" in the LLM-designed schema, as opposed to separating dining into specific categories like \"breakfast,\" \"lunch,\" and \"dinner.\" In practice, this simplification often leads the LLM to allocate only a single meal per day, which contradicts commonsense expectations for travel planning.

## Ablation Study

We conducted an ablation study using GPT-4o-mini on the Calendar Scheduling task to evaluate the individual contributions of schema design and reasoning verification . Table [\[tab:ablation_study\]](#tab:ablation_study) shows that when reasoning verification is removed, accuracy drops from 42.3% to 38.5% ([$\downarrow$ 3.8%]{style="color: red"}). This indicates that without explicitly verifying constraints, the LLM may overlook key restrictions in the query, leading to false positives during self-checking. The absence of schema design leads to a larger performance drop, from 42.3% to 36.2% ([$\downarrow$ 6.1%]{style="color: red"}), and further to 32.7% ([$\downarrow$ 9.6%]{style="color: red"}) when both schema design and reasoning verification are removed. This highlights the critical role of schema design in structuring the reasoning process. Table [\[tab:w_wo_schema\]](#tab:w_wo_schema) shows that without a schema, the LLM tends to create tables with fewer columns, omitting key information necessary for constraint checking. While the table without schema design contains basic headers such as `Participant` and `Selected Meeting Time`, the schema-designed table includes additional headers like `Conflict Check`, `Work Hours Start/End`, and `Notes/Comments`. These additional columns capture critical reasoning steps and constraints, enabling more effective verification and selection of a valid meeting time.

# Conclusion

We proposed Table as Thought, a novel framework that introduces structured reasoning at the thought level. The framework centers on the design and utilization of table schemas, where the LLM is tasked with constructing a schema and generating structured thoughts based on it. Our results demonstrate that Table as Thought excels in constraint planning tasks, showcasing its ability to manage complex constraints effectively. Moreover, the framework exhibits significant potential for further improving performance in math reasoning tasks, particularly in addressing unsolved problems through structured reasoning.

Additionally, we conducted detailed analyses of the results, exploring the interplay between schema design, reasoning complexity, and model capabilities. These insights pave the way for future research into the nature and representation of thought processes, offering a promising direction for the development of more robust reasoning frameworks in LLMs.

# Limitations {#limitations .unnumbered}

Our proposed methods are currently supported only by models capable of generating structured data with complex schemas. This limitation restricts our experiments to a small set of closed-source models, such as those provided by OpenAI. Consequently, the generalizability of our findings to open-source LLMs remains unexplored. Future work should investigate approaches for adapting Table as Thought to a broader range of models, including those with limited native support for structured data generation.

# Ethical Statement {#ethical-statement .unnumbered}

This research was conducted using publicly available datasets (e.g., GSM-8K, MATH500, TravelPlanner) in compliance with their terms of use, ensuring no personally identifiable information (PII) was processed. While our proposed framework, Table as Thought, aims to enhance structured reasoning in LLMs, we acknowledge the potential risks of misuse in harmful applications, such as deceptive planning or adversarial reasoning. To mitigate this, we advocate for responsible deployment with appropriate safeguards.
