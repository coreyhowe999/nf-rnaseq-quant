process MULTIQC {
    label 'process_low'
    publishDir "${params.outdir}/multiqc", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    input:
    path '*'   // any QC outputs piled into the working dir

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data",        emit: data
    path "versions.yml",        emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    multiqc -f ${args} .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}
