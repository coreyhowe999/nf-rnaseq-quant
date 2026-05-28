process FASTP {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}/fastp", mode: params.publish_dir_mode,
        saveAs: { fn -> fn.endsWith('.fastq.gz') ? "trimmed/${fn}" : "reports/${fn}" }

    container 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.trimmed.fastq.gz"), emit: reads
    tuple val(meta), path("*.fastp.json"),       emit: json
    tuple val(meta), path("*.fastp.html"),       emit: html
    path  "versions.yml",                         emit: versions

    script:
    def args = task.ext.args ?: ''
    def r1 = reads[0]
    def r2 = reads[1]
    """
    fastp \\
        --in1 ${r1} \\
        --in2 ${r2} \\
        --out1 ${meta.id}_1.trimmed.fastq.gz \\
        --out2 ${meta.id}_2.trimmed.fastq.gz \\
        --json ${meta.id}.fastp.json \\
        --html ${meta.id}.fastp.html \\
        --thread ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //')
    END_VERSIONS
    """
}
