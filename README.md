# nf-rnaseq-quant

A reproducible **Nextflow DSL2** pipeline for bulk RNA-seq transcript quantification.
Trims reads, quantifies against a reference transcriptome with [Salmon](https://salmon.readthedocs.io),
and produces a per-sample QC report aggregated with [MultiQC](https://multiqc.info).

Designed to be small, readable, and easy to drop into a Slurm/AWS Batch cluster — the same
pipeline definition runs locally on a laptop, on a workstation with Docker, or on HPC.

## What it does

```
                ┌──────────┐
   FASTQ ─┬───► │ FastQC   │ ─┐
          │     └──────────┘  │
          │     ┌──────────┐  │     ┌─────────────┐     ┌────────┐
          └───► │ fastp    │ ─┼───► │ Salmon quant│ ──► │MultiQC │
                └──────────┘  │     └─────────────┘     └────────┘
                              │            ▲
                              │            │
                Transcriptome FASTA ───► Salmon index
```

Per sample: raw QC, adapter/quality trimming, pseudo-alignment quant, and a unified HTML report.

## Quickstart

```bash
# Run with the bundled test profile (downloads tiny test data; ~2 min on a laptop)
nextflow run coreyhowe999/nf-rnaseq-quant -profile test,docker

# Run on your own data
nextflow run coreyhowe999/nf-rnaseq-quant \
    --samplesheet samplesheet.csv \
    --transcriptome /path/to/transcripts.fa.gz \
    --outdir results \
    -profile docker
```

Requirements: `nextflow ≥ 23.10`, and one of: `docker`, `singularity`, or local installs of
`fastqc`, `fastp`, `salmon`, `multiqc`.

## Samplesheet format

CSV with header `sample,fastq_1,fastq_2`. Paired-end only.

```csv
sample,fastq_1,fastq_2
SRR1_rep1,/data/SRR1_R1.fastq.gz,/data/SRR1_R2.fastq.gz
SRR1_rep2,/data/SRR2_R1.fastq.gz,/data/SRR2_R2.fastq.gz
```

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `--samplesheet` | CSV with `sample,fastq_1,fastq_2` columns | — |
| `--transcriptome` | Reference transcriptome FASTA (`.fa` or `.fa.gz`) | — |
| `--outdir` | Output directory | `./results` |
| `--salmon_libtype` | Salmon library type | `A` (auto) |
| `--skip_trim` | Skip fastp trimming step | `false` |
| `--skip_multiqc` | Skip MultiQC aggregation | `false` |

## Outputs

```
results/
├── fastqc/             # per-sample FastQC HTML + zip
├── fastp/              # trimmed FASTQs + JSON/HTML reports
├── salmon/
│   ├── index/          # Salmon index (one per run)
│   └── <sample>/       # quant.sf + auxiliary stats per sample
└── multiqc/
    └── multiqc_report.html
```

## Profiles

The pipeline ships with composable profiles in [`nextflow.config`](nextflow.config):

- `test` — uses bundled tiny test data; runs end-to-end in ~2 min
- `docker` / `singularity` — pulls containerized tools
- `slurm` — submits each process as a Slurm job (edit `conf/slurm.config` for your queue)

Stack them with commas: `-profile test,docker`.

## Repository layout

```
.
├── main.nf                 # entry point — parses params, calls workflow
├── workflows/rnaseq.nf     # workflow definition (DAG)
├── modules/                # one process per file
│   ├── fastqc.nf
│   ├── fastp.nf
│   ├── salmon_index.nf
│   ├── salmon_quant.nf
│   └── multiqc.nf
├── conf/                   # base resources + profile configs
├── assets/                 # test samplesheet, schema
└── nextflow.config         # entrypoint config + profile registry
```

## License

MIT — see [LICENSE](LICENSE).
