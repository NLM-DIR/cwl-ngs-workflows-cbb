class: Workflow
cwlVersion: v1.2

id: gatk-genotyping-cohort
doc: |
  Create single cohort workflow using the GATK4
  Pipeline implemented from: https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/-cohort

inputs:
  reference_fasta:
    type: File
    secondaryFiles:
      - ".fai"
      - "^.dict"
  vcf_files:
    type: File[]
  output: string
  java_options: string?
  threads: int?
  ploidy: int?
  snp_filters:
    type: { "type": "array", "items": { "type": "array", "items": "string" } }
  indel_filters:
    type: { "type": "array", "items": { "type": "array", "items": "string" } }

outputs:
  snp_out:
    outputSource: gatk_select_variants_snp_filtered/output
    type: File
    secondaryFiles: [ .idx ]
  indels_out:
    outputSource: gatk_select_variants_indels_filtered/output
    type: File
    secondaryFiles: [ .idx ]

steps:
  gather_vcf:
    run: ../../tools/gatk/gatk-GatherVcfs.cwl
    in:
      I: vcf_files
      O: output
      java_options: java_options
    out: [ output ]
  gatk_select_variants_snp:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      R: reference_fasta
      V: gather_vcf/output
      selectType: { default: "SNP" }
      O:
        valueFrom: ${ return inputs.V.nameroot + "_snps.vcf"; }
    out: [ output ]
  gatk_select_variants_indels:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      R: reference_fasta
      V: gather_vcf/output
      selectType: { default: "INDEL" }
      O:
        valueFrom: ${ return inputs.V.nameroot + "_indels.vcf"; }
    out: [ output ]
  gatk_variant_filtration_snp:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      R: reference_fasta
      V: gatk_select_variants_snp/output
      O:
        valueFrom: ${ return inputs.V.nameroot + "_filtered.vcf"; }
      filters: snp_filters
    out: [ output ]
  gatk_variant_filtration_indels:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      R: reference_fasta
      V: gatk_select_variants_indels/output
      O:
        valueFrom: ${ return inputs.V.nameroot + "_filtered.vcf"; }
      filters: indel_filters
    out: [ output ]
  gatk_select_variants_snp_filtered:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      V: gatk_variant_filtration_snp/output
      exclude-filtered: { default: True }
      O:
        valueFrom: ${ return inputs.V.nameroot + "_final.vcf"; }
    out: [ output ]
  gatk_select_variants_indels_filtered:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      V: gatk_variant_filtration_indels/output
      exclude-filtered: { default: True }
      O:
        valueFrom: ${ return inputs.V.nameroot + "_final.vcf"; }
    out: [ output ]
