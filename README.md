# End-to-end LLM Workflows Guide (modified for Perlmutter Supercomputer)

Modified from https://github.com/anyscale/e2e-llm-workflows

In this guide, we'll learn how to execute the end-to-end LLM workflows to develop & productionize LLMs at scale.

- **Data preprocessing**: prepare our dataset for fine-tuning with batch data processing.
- **Fine-tuning**: tune our LLM (LoRA / full param) with key optimizations with distributed training.
- **Evaluation**: apply batch inference with our tuned LLMs to generate outputs and perform evaluation.
- **Serving**: serve our LLMs as a production application that can autoscale, swap between LoRA adapters, etc.

Throughout these workloads we'll be using [Ray](https://github.com/ray-project/ray), a framework for distributing ML and the NERSC [Perlmutter](https://docs.nersc.gov/systems/perlmutter/architecture/) Supercomputer.

To start visit the [notebook](Perlmutter_Ray_LLM.ipynb).