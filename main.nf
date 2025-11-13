#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/rarevariantburden
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/rarevariantburden
    Website: https://nf-co.re/rarevariantburden
    Slack  : https://nfcore.slack.com/channels/rarevariantburden
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { RAREVARIANTBURDEN  } from './workflows/rarevariantburden'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_rarevariantburden_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_rarevariantburden_pipeline'
//include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_rarevariantburden_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
//params.fasta = getGenomeAttribute('fasta')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_RAREVARIANTBURDEN {

    take:
    caseJointVCF // caseJointVCF read in from --caseJointVCF
    caseSample // caseSample read in from --caseSample

    main:

    //
    // WORKFLOW: Run pipeline
    //
    RAREVARIANTBURDEN (
        caseJointVCF, caseSample
    )
    emit:
    association_res = RAREVARIANTBURDEN.out.association_res // channel: /path/to/association.tsv
    qqplot = RAREVARIANTBURDEN.out.qqplot // channel: /path/to/association.tsv.dominant.nRep1000.pdf
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.caseJointVCF,
        params.caseSample
    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_RAREVARIANTBURDEN (
        PIPELINE_INITIALISATION.out.caseJointVCF, PIPELINE_INITIALISATION.out.caseSample
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        NFCORE_RAREVARIANTBURDEN.out.association_res,
        NFCORE_RAREVARIANTBURDEN.out.qqplot
    )
}

workflow.onComplete {
    def is_healthomics = params.outdir?.startsWith('/mnt/workflow') ?: false

    if (is_healthomics) {
        // The report files are written relative to where Nextflow was launched
        def sourceDir = file("${params.outdir}/pipeline_info")

        def omics_workflow_id = System.getenv('OMICS_WORKFLOW_ID')
        def omics_output_uri = System.getenv('OMICS_RUN_OUTPUT_URI')
        def omics_run_id = System.getenv('OMICS_RUN_ID')

        log.info "Running on AWS HealthOmics"
        log.info "Workflow ID: ${omics_workflow_id}"
        log.info "Run ID: ${omics_run_id}"
        log.info "Output URI: ${omics_output_uri}"
        log.info "Launch directory: ${workflow.launchDir}"

        log.info """
        === Workflow Configuration ===
        Params outdir: ${params.outdir}
        Workflow launchDir: ${workflow.launchDir}
        Workflow workDir: ${workflow.workDir}
        Workflow projectDir: ${workflow.projectDir}
        Workflow outputDir: ${workflow.outputDir}
        Workflow runName: ${workflow.runName}
        Workflow sessionId: ${workflow.sessionId}
        ===========================
        """.stripIndent()

        def metadataFile = file('/mnt/workflow/run-metadata.json')

        if (metadataFile.exists()) {
            def metadata = new groovy.json.JsonSlurper().parseText(metadataFile.text)
            def runOutputUri = metadata.outputUri ?: metadata.runOutputUri

            log.info "Run Output URI from metadata: ${runOutputUri}"

            // Use this URI for copying pipeline_info
            def destDir = file("${runOutputUri}/pipeline_info")
            // ... rest of your copy logic

            if (sourceDir.exists()) {
                // Copy entire directory
                sourceDir.copyTo(destDir)
                log.info "✓ Pipeline info copied to ${destDir}"
            } else {
                // Files might be directly in launchDir
                def destDirFile = file(destDir)
                destDirFile.mkdirs()

                def patterns = ["execution_timeline*.html", "execution_report*.html",
                            "execution_trace*.txt", "pipeline_dag*.html"]

                patterns.each { pattern ->
                    file("${workflow.launchDir}").listFiles().findAll {
                        it.name.matches(pattern.replace('*', '.*'))
                    }.each {
                        it.copyTo("${destDir}/${it.name}")
                        log.info "✓ Copied ${it.name} to ${destDir}"
                    }
                }
            }
        } else {
            log.warn "Run metadata file not found"
        }

    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
