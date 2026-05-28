process SALMON_INDEX {
    tag "${transcriptome.simpleName}"
    label 'process_medium'
    publishDir "${params.outdir}/salmon", mode: params.publish_dir_mode

    container 'biocontainers/salmon:1.10.2--h7e5ed60_0'

    input:
    path transcriptome

    output:
    path "index",         emit: index
    path "versions.yml",  emit: versions

    script:
    def args = task.ext.args ?: '--threads ' + task.cpus
    def is_gz = transcriptome.name.endsWith('.gz')
    def prep = is_gz ? "gunzip -c ${transcriptome} > tx.fa" : "cp ${transcriptome} tx.fa"
    """
    ${prep}

    salmon index \\
        --transcripts tx.fa \\
        --index index \\
        --kmerLen 31 \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version 2>&1 | sed 's/salmon //')
    END_VERSIONS
    """
}
