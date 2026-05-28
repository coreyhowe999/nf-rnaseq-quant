#!/usr/bin/env nextflow

/*
 * nf-rnaseq-quant — bulk RNA-seq quantification with Salmon
 * Entry point. Parses params, validates inputs, hands off to the workflow.
 */

nextflow.enable.dsl = 2

include { RNASEQ } from './workflows/rnaseq.nf'

// ---- Param validation -------------------------------------------------------

def requiredParams = ['samplesheet', 'transcriptome', 'outdir']
requiredParams.each { p ->
    if (params[p] == null) {
        exit 1, "Missing required parameter: --${p}\nRun with -profile test,docker for a quick sanity check, or see README.md."
    }
}

def samplesheetFile = file(params.samplesheet)
if (!samplesheetFile.exists()) {
    exit 1, "Samplesheet not found: ${params.samplesheet}"
}

def transcriptomeFile = file(params.transcriptome)
if (!transcriptomeFile.exists()) {
    exit 1, "Transcriptome FASTA not found: ${params.transcriptome}"
}

// ---- Header -----------------------------------------------------------------

log.info """
nf-rnaseq-quant
================================
samplesheet   : ${params.samplesheet}
transcriptome : ${params.transcriptome}
outdir        : ${params.outdir}
trim          : ${!params.skip_trim}
multiqc       : ${!params.skip_multiqc}
profile       : ${workflow.profile}
""".stripIndent()

// ---- Run --------------------------------------------------------------------

workflow {
    // Parse samplesheet into a channel of [meta, [read1, read2]] tuples
    reads_ch = Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            if (!row.sample || !row.fastq_1 || !row.fastq_2) {
                exit 1, "Samplesheet row missing required columns (sample,fastq_1,fastq_2): ${row}"
            }
            def meta = [ id: row.sample ]
            def reads = [ file(row.fastq_1, checkIfExists: true),
                          file(row.fastq_2, checkIfExists: true) ]
            tuple(meta, reads)
        }

    transcriptome_ch = Channel.fromPath(params.transcriptome, checkIfExists: true)

    RNASEQ(reads_ch, transcriptome_ch)
}

workflow.onComplete {
    log.info "Pipeline complete: ${workflow.success ? 'OK' : 'FAILED'}"
    log.info "Results: ${params.outdir}"
}
