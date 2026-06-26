class: Workflow
cwlVersion: v1.2

id: gatk-variant-calling
doc: |
  Variant calling workflow using the GATK4
  Pipeline implemented from: https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/

requirements:
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  R: string
  reads: File[]
  genome_fasta:
    type: File
    secondaryFiles: [.fai, ^.dict]
  genome_index: Directory
  genome_prefix: string
  threads: int
  ploidy: int?
  java_options: string?
  annotations: string[]?
  missing_values_evaluate_as_failing: string?
  snp_filters:
    type: {"type": "array", "items": {"type": "array", "items": "string"}}
  indel_filters:
    type: {"type": "array", "items": {"type": "array", "items": "string"}}

outputs:
  bam_flagstat_out:
    outputSource: alignment/bam_flagstat_out
    type: File
  bam_stats_out:
    outputSource: alignment/bam_stats_out
    type: File
  sorted_indexed_bam:
    outputSource: bam_recal/output
    type: File
    secondaryFiles: [.bai,.sbi]
  mark_duplicates_metrics:
    outputSource: mark_duplicates/metrics
    type: File
  gvcf_file:
    outputSource: gatk_haplotypecaller_recal/output
    type: File
    secondaryFiles: [ .tbi ]
  baserecalibrator_table:
    outputSource: gatk_baserecalibrator_post/output
    type: File

steps:
  alignment:
    run: bwa-alignment-sort.cwl
    in:
      R: R
      reads: reads
      genome_index: genome_index
      genome_prefix: genome_prefix
      threads: threads
    out: [sorted_indexed_bam, bam_flagstat_out, bam_stats_out]
  mark_duplicates:
    run: ../../tools/gatk/gatk-MarkDuplicates.cwl
    in:
      java_options: java_options
      I: alignment/sorted_indexed_bam
      O:
        valueFrom: ${ return inputs.I.nameroot + "_sorted_dedup_reads.bam"; }
      M:
        valueFrom: ${ return inputs.I.nameroot + "_dedup_metrics.txt"; }
    out: [output, metrics]
  index_bam:
    run: ../../tools/samtools/samtools-index.cwl
    in:
      in_bam: mark_duplicates/output
    out: [out_sam]
  index_split_bam:
    run: ../../tools/gatk/gatk-CreateHadoopBamSplittingIndex.cwl
    in:
      java_options: java_options
      I: index_bam/out_sam
      O:
        valueFrom: ${ return inputs.I.basename + ".sbi"; }
    out: [output]
  gatk_haplotypecaller_pre:
    run: ../../tools/gatk/gatk-HaplotypeCaller.cwl
    in:
      threads: threads
      R: genome_fasta
      I: index_split_bam/output
      java_options: java_options
      ploidy: ploidy
      annotations: annotations
      O:
        valueFrom: ${ return inputs.I.nameroot + "_raw_variants.vcf"; }
    out: [output]
  index_haplotypecaller_vcf:
    run: ../../tools/gatk/gatk-IndexFeatureFile.cwl
    in:
      java_options: java_options
      I: gatk_haplotypecaller_pre/output
    out: [output]
  gatk_select_variants_snp:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      java_options: java_options
      R: genome_fasta
      V: index_haplotypecaller_vcf/output
      selectType: { default: "SNP"}
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_variants", "_snps.vcf"); }
    out: [output]
  gatk_select_variants_indels:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      java_options: java_options
      R: genome_fasta
      V: index_haplotypecaller_vcf/output
      selectType: { default: "INDEL"}
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_variants", "_indels.vcf"); }
    out: [output]
  gatk_variant_filtration_snp:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      java_options: java_options
      R: genome_fasta
      V: gatk_select_variants_snp/output
      missing_values_evaluate_as_failing: missing_values_evaluate_as_failing
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_raw_snps", "_filtered_snps.vcf"); }
      filters: snp_filters
    out: [output]
  gatk_variant_filtration_indels:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      java_options: java_options
      R: genome_fasta
      V: gatk_select_variants_indels/output
      missing_values_evaluate_as_failing: missing_values_evaluate_as_failing
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_raw_indels", "_filtered_indels.vcf"); }
      filters: indel_filters
    out: [output]
  gatk_select_variants_snp_filtered:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      java_options: java_options
      V: gatk_variant_filtration_snp/output
      exclude-filtered: { default: True}
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_filtered_snps", "_bqsr_snps.vcf"); }
    out: [output]
  gatk_select_variants_indels_filtered:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      java_options: java_options
      V: gatk_variant_filtration_indels/output
      exclude-filtered: { default: True}
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_filtered_indels", "_bqsr_indels.vcf"); }
    out: [output]
  gatk_baserecalibrator_pre:
    run: ../../tools/gatk/gatk-BaseRecalibrator.cwl
    in:
      java_options: java_options
      R: genome_fasta
      I: index_bam/out_sam
      known_sites:
        - gatk_select_variants_snp_filtered/output
        - gatk_select_variants_indels_filtered/output
      O:
        valueFrom: ${ return inputs.I.nameroot.replace("_sorted_sorted_dedup_reads", "_recal_data.table"); }
    out: [output]
  gatk_applybqsr:
    run: ../../tools/gatk/gatk-ApplyBQSR.cwl
    in:
      java_options: java_options
      R: genome_fasta
      I: index_bam/out_sam
      bqsr: gatk_baserecalibrator_pre/output
      O:
        valueFrom: ${ return inputs.I.nameroot.replace("_sorted_sorted_dedup_reads", "_recal_reads.bam"); }
    out: [output]
  recal_reads_bam_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: gatk_applybqsr/output
    out: [out_sam]
  index_bam_recal:
    run: ../../tools/gatk/gatk-CreateHadoopBamSplittingIndex.cwl
    in:
      java_options: java_options
      I: recal_reads_bam_index/out_sam
      O:
        valueFrom: ${ return inputs.I.basename + ".sbi"; }
    out: [ output ]
  gatk_baserecalibrator_post:
    run: ../../tools/gatk/gatk-BaseRecalibrator.cwl
    in:
      java_options: java_options
      R: genome_fasta
      I: index_bam_recal/output
      known_sites:
        - gatk_select_variants_snp_filtered/output
        - gatk_select_variants_indels_filtered/output
      O:
        valueFrom: ${ return inputs.I.nameroot.replace("_recal_reads", "_post_recal_data.table"); }
    out: [output]
  bam_recal:
    run: ../../tools/gatk/gatk-CreateHadoopBamSplittingIndex.cwl
    in:
      java_options: java_options
      I: recal_reads_bam_index/out_sam
      O:
        valueFrom: ${ return inputs.I.basename + ".sbi"; }
    out: [ output ]
  gatk_haplotypecaller_recal:
    run: ../../tools/gatk/gatk-HaplotypeCaller.cwl
    in:
      threads: threads
      R: genome_fasta
      I: bam_recal/output
      ploidy: ploidy
      ERC: { default: "GVCF" }
      create_output_variant_index: { default: "true" }
      annotations: annotations
      java_options: java_options
      O:
        valueFrom: ${ return inputs.I.nameroot + "_variants.g.vcf.gz"; }
    out: [output]
