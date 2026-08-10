# References

The repository does not depend on link-following to make its argument. Complete titles, venues, DOI or arXiv identifiers are given here so every citation is independently searchable.

1. **Patrick Lewis et al..** “Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks.” *NeurIPS 2020*. arXiv:2005.11401.

2. **Vladimir Karpukhin et al..** “Dense Passage Retrieval for Open-Domain Question Answering.” *EMNLP 2020*. doi:10.18653/v1/2020.emnlp-main.550.

3. **Nils Reimers and Iryna Gurevych.** “Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks.” *EMNLP-IJCNLP 2019*. doi:10.18653/v1/D19-1410.

4. **Fengbin Zhu et al..** “TAT-QA: A Question Answering Benchmark on a Hybrid of Tabular and Textual Content in Finance.” *ACL-IJCNLP 2021*. doi:10.18653/v1/2021.acl-long.254.

5. **Fengbin Zhu et al..** “Towards Complex Document Understanding By Discrete Reasoning.” *TAT-DQA, 2022*. arXiv:2207.11871.

6. **Fengbin Zhu et al..** “Doc2SoarGraph: Discrete Reasoning over Visually-Rich Table-Text Documents via Semantic-Oriented Hierarchical Graphs.” *2023*. arXiv:2305.01938.

7. **Fengbin Zhu et al..** “TAT-LLM: A Specialized Language Model for Discrete Reasoning over Tabular and Textual Data.” *2024*. arXiv:2401.13223.

8. **Zhengbao Jiang et al..** “Active Retrieval Augmented Generation.” *2023*. arXiv:2305.06983.

9. **Akari Asai et al..** “Self-RAG: Learning to Retrieve, Generate, and Critique through Self-Reflection.” *2023*. arXiv:2310.11511.

10. **Shi-Qi Yan et al..** “Corrective Retrieval Augmented Generation.” *2024*. arXiv:2401.15884.

11. **Qinyuan Cheng et al..** “Unified Active Retrieval for Retrieval Augmented Generation.” *2024*. arXiv:2406.12534.

12. **Shahul Es et al..** “RAGAS: Automated Evaluation of Retrieval Augmented Generation.” *2023*. arXiv:2309.15217.

13. **Jon Saad-Falcon et al..** “ARES: An Automated Evaluation Framework for Retrieval-Augmented Generation Systems.” *2023*. arXiv:2311.09476.

14. **Dongyu Ru et al..** “RAGChecker: A Fine-grained Framework for Diagnosing Retrieval-Augmented Generation.” *2024*. arXiv:2408.08067.

15. **Tim Dettmers et al..** “QLoRA: Efficient Finetuning of Quantized LLMs.” *2023*. arXiv:2305.14314.

16. **Qwen Team.** “Qwen2.5 Technical Report.” *2024*. arXiv:2412.15115.

17. **Shijia Xu et al..** “Self-Correcting RAG: Enhancing Faithfulness via MMKP Context Selection and NLI-Guided MCTS.” *Findings of ACL 2026*. doi:10.18653/v1/2026.findings-acl.1052.

18. **Haiyan Wu et al..** “Reflective RAG: Self-Evaluation Driven Strategy Optimization in Agentic Retrieval-Augmented Generation.” *Findings of ACL 2026*. doi:10.18653/v1/2026.findings-acl.648.

19. **Akshay Verma et al..** “ReflectiveRAG: Rethinking Adaptivity in Retrieval-Augmented Generation.” *EACL Industry 2026*. doi:10.18653/v1/2026.eacl-industry.27.

20. **Yongfeng Huang et al..** “SEMA-RAG: A Self-Evolving Multi-Agent Retrieval-Augmented Generation Framework for Medical Reasoning.” *Findings of ACL 2026*. doi:10.18653/v1/2026.findings-acl.917.

21. **Bo Li et al..** “Retrieval as Generation: A Unified Framework with Self-Triggered Information Planning.” *ACL 2026*. doi:10.18653/v1/2026.acl-long.196.

22. **Dheeru Dua et al..** “DROP: A Reading Comprehension Benchmark Requiring Discrete Reasoning Over Paragraphs.” *2019*. arXiv:1903.00161.

23. **Zeyu Zhang, Thuy Vu, Alessandro Moschitti.** “Joint Models for Answer Verification in Question Answering Systems.” *ACL-IJCNLP 2021*. doi:10.18653/v1/2021.acl-long.252.

24. **Jeffrey O. Kephart and David M. Chess.** “The Vision of Autonomic Computing.” *Computer 36(1), 2003*. doi:10.1109/MC.2003.1160055.

25. **Mazeiar Salehie and Ladan Tahvildari.** “Self-Adaptive Software: Landscape and Research Challenges.” *ACM TAAS 4(2), 2009*. self-adaptive systems reference.

26. **Yuning Mao et al..** “Generation-Augmented Retrieval for Open-Domain Question Answering.” *ACL-IJCNLP 2021*. ACL Anthology: 2021.acl-long.316.

27. **Yifan Gao et al..** “Answering Ambiguous Questions through Generative Evidence Fusion and Round-Trip Prediction.” *ACL-IJCNLP 2021*. ACL Anthology: 2021.acl-long.253.

## Priority-search note

The literature boundary used in this repository is deliberately narrow. Earlier work clearly contains adaptive retrieval, self-reflection, corrective retrieval, self-evaluation, answer verification, and self-correction. The claim made here is not that those ideas did not exist. The claim is that this implementation makes retrieval healing an explicit **transaction system over persistent RAG state** with a discrete residual, protected support, strict commit/rollback, durable transaction history, cycle detection, and bounded autonomous escalation.
