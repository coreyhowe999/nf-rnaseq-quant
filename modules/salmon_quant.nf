process SALMON_QUANT {
    tag "${meta.id}"
    label 'process_high'
    publishDir "${params.outdir}/salmon", mode: params.publish_dir_mode

    container 'biocontainers/salmon:1.10.2--h7e5ed60_0'

    input:
    tuple val(meta), path(reads)
    path  index

    output:
    tuple val(meta), path("${meta.id}"), emit: quant
    path  "versions.yml",                emit: versions

    script:
    def args = task.ext.args ?: ''
    def libtype = params.salmon_libtype ?: 'A'
    def r1 = reads[0]
    def r2 = reads[1]
    """
    salmon quant \\
        --index ${index} \\
        --libType ${libtype} \\
        -1 ${r1} \\
        -2 ${r2} \\
        --threads ${task.cpus} \\
        --validateMappings \\
        --gcBias \\
        --output ${meta.id} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version 2>&1 | sed 's/salmon //')
    END_VERSIONS
    """
}
