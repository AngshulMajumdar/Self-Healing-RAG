# Reproducibility

## Recorded machine

- Windows 11.
- Python 3.12.13 under JupyterLab Desktop.
- NVIDIA GeForce RTX 4060 Laptop GPU, 8 GB VRAM.
- Approximately 16 GB system RAM.
- CUDA-enabled PyTorch runtime.
- Qwen2.5-7B-Instruct, local 4-bit NF4 loading.
- SentenceTransformers, ChromaDB, FAISS and LangGraph installed in the local environment.

## Recorded retrieval store

- Collection: `tatdqa_evidence_v1`.
- Records: 3,838 active searchable units.
- Embedder: `sentence-transformers/all-MiniLM-L6-v2`.
- Dimension: 384.
- Similarity: cosine over L2-normalized embeddings.

## Split contract

- 963 development questions.
- 312 validation questions.
- 324 test questions.
- Document disjointness checked before evaluation.

## Rerun order

The complete historical order is preserved in `EXECUTED_PIPELINE.md`. That file includes local migration verification, Chroma verification, vector-search evaluation, local model loading, semantic observation, Loop 1 and Loop 2 transactions and recoveries, autonomous retrieval control, answer generation, contract recovery, escalation resolution, practical validation and the terminal POC resolver.

## Gold isolation

Gold requirements in the retrieval benchmark are used only by offline retrieval evaluation. Gold answers are read only after prediction files are durably frozen. No gold answer is passed into retrieval, repair, generation, verification or controller routing.

## What is not bundled

This GitHub-ready repository does not bundle model weights, the benchmark source documents, the persistent Chroma binary store or local caches. Those artifacts are governed by their own licenses and are large enough that including them would make the repository less useful. The executed transcript records the exact expected paths and integrity checks.
