main() {
    CoCoRVFolder=$1
    cocorvOut=$2
    topK=$3
    caseControl=$4
    reference=$5
    sampleList=$6
    annotationTool=$7
    chr=$8

    vcfSuffix=".biallelic.leftnorm.ABCheck.vcf.gz"
    vcfAnnoSuffix=".annotated.vcf.gz"
    outputFile="${chr}.top${topK}.${cocorvOut}.${caseControl}.variants.tsv"
    fullGenotype=T

    if [[ ${annotationTool} == "ANNOVAR" ]]; then
        annotations="Gene.refGene,FILTER,Func.refGene,ExonicFunc.refGene,AAChange.refGene,REVEL"
    elif [[ ${annotationTool} == "VEP" ]]; then
        annotations="SYMBOL,FILTER,Consequence,HGVSp,am_class,am_pathogenicity,SpliceAI_pred_DP_AG,SpliceAI_pred_DP_AL,SpliceAI_pred_DP_DG,SpliceAI_pred_DP_DL,SpliceAI_pred_DS_AG,SpliceAI_pred_DS_AL,SpliceAI_pred_DS_DG,SpliceAI_pred_DS_DL,LoF,LoF_filter,LoF_flags,LoF_info,CADD_PHRED,CADD_RAW"
    elif [[ ${annotationTool} == "ANNOVAR_VEP" ]]; then
        annotations="Gene.refGene,FILTER,Func.refGene,ExonicFunc.refGene,AAChange.refGene,REVEL,am_class,am_pathogenicity,SpliceAI_pred_DP_AG,SpliceAI_pred_DP_AL,SpliceAI_pred_DP_DG,SpliceAI_pred_DP_DL,SpliceAI_pred_DS_AG,SpliceAI_pred_DS_AL,SpliceAI_pred_DS_DG,SpliceAI_pred_DS_DL,LoF,LoF_filter,LoF_flags,LoF_info,CADD_PHRED,CADD_RAW"
    fi

    bash postCheckCoCoRV_docker.sh ${cocorvOut} ${topK} \
        ${vcfAnnoSuffix} ${outputFile} ${caseControl} ${fullGenotype} ${sampleList} ${reference} ${annotations} ${vcfSuffix}
}

main "$@"
