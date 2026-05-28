/*
 * RNASEQ workflow
 *  reads_ch          : Channel<tuple(meta, [r1, r2])>
 *  transcriptome_ch  : Channel<path>
 *
 * Steps:
 *   1. FastQC on raw reads
 *   2. (optional) fastp trim
 *   3. Salmon index (once) + Salmon quant per sample
 *   4. (optional) MultiQC aggregate report
 */

include { FASTQC        } from '../modules/fastqc.nf'
include { FASTP         } from '../modules/fastp.nf'
include { SALMON_INDEX  } from '../modules/salmon_index.nf'
include { SALMON_QUANT  } from '../modules/salmon_quant.nf'
include { MULTIQC       } from '../modules/multiqc.nf'

workflow RNASEQ {
    take:
    reads_ch
    transcriptome_ch

    main:
    ch_versions = Channel.empty()
    ch_multiqc  = Channel.empty()

    // 1. Raw-read QC
    FASTQC(reads_ch)
    ch_versions = ch_versions.mix(FASTQC.out.versions)
    ch_multiqc  = ch_multiqc.mix(FASTQC.out.report.map { _meta, files -> files })

    // 2. Optional trim
    if (!params.skip_trim) {
        FASTP(reads_ch)
        trimmed_ch = FASTP.out.reads
        ch_versions = ch_versions.mix(FASTP.out.versions)
        ch_multiqc  = ch_multiqc.mix(FASTP.out.json.map { _meta, f -> f })
    } else {
        trimmed_ch = reads_ch
    }

    // 3. Index + quant
    SALMON_INDEX(transcriptome_ch)
    SALMON_QUANT(trimmed_ch, SALMON_INDEX.out.index.collect())
    ch_versions = ch_versions.mix(SALMON_INDEX.out.versions, SALMON_QUANT.out.versions)
    ch_multiqc  = ch_multiqc.mix(SALMON_QUANT.out.quant.map { _meta, d -> d })

    // 4. Aggregate report
    if (!params.skip_multiqc) {
        MULTIQC(ch_multiqc.collect())
    }

    emit:
    quant    = SALMON_QUANT.out.quant
    versions = ch_versions
}
