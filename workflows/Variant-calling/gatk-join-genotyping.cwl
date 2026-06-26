class: Workflow
cwlVersion: v1.2

id: gatk-join-genotyping
doc: |
  Join Genotyping workflow using the GATK4
  Pipeline implemented from: https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/

requirements:
  MultipleInputFeatureRequirement: { }
  InlineJavascriptRequirement: { }
  StepInputExpressionRequirement: { }
  SubworkflowFeatureRequirement: { }
  ScatterFeatureRequirement: { }

inputs:
  reference_fasta:
    type: File
    secondaryFiles: [ .fai, ^.dict ]
  gvcf_files:
    type: File[]
    secondaryFiles: [ .tbi ]
  interval: string
  java_options: string?
  threads: int?
  ploidy: int?
  snp_filters:
    type: { "type": "array", "items": { "type": "array", "items": "string" } }
  indel_filters:
    type: { "type": "array", "items": { "type": "array", "items": "string" } }

outputs:
  genotyped_vcf:
    outputSource: join_interval/output
    type: File
  indexed_vcf_snp_file:
    outputSource: variant_filtration_snp/output
    type: File
    secondaryFiles: [ .tbi ]
  indexed_vcf_indels_file:
    outputSource: variant_filtration_indels/output
    type: File
    secondaryFiles: [ .tbi ]

steps:
  create_db:
    run: ../../tools/gatk/gatk-qq.cwl
    in:
      java_options: java_options
      genomicsdb_workspace_path:
        valueFrom: ${ return "cohort_db." + inputs.L; }
      L: interval
      V: gvcf_files
      threads: threads
    out: [ output ]
  join_interval:
    run: ../../tools/gatk/gatk-GenotypeGVCFs.cwl
    in:
      java_options: java_options
      R: reference_fasta
      V: create_db/output
      include_non_variant_sites: { default: true }
      ploidy: ploidy
      O:
        valueFrom: ${ return inputs.V.nameroot + "_genotyped.vcf.gz"; }
    out: [ output ]
  select_variants_snp:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      R: reference_fasta
      V: join_interval/output
      selectType: { default: "SNP" }
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_genotyped.vcf", "_raw_snps.vcf.gz"); }
    out: [ output ]
  variant_filtration_snp:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      R: reference_fasta
      V: select_variants_snp/output
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_raw_snps.vcf", "_filtered_snps.vcf.gz"); }
      filters: snp_filters
    out: [ output ]
  select_variants_indels:
    run: ../../tools/gatk/gatk-SelectVariants.cwl
    in:
      R: reference_fasta
      V: join_interval/output
      selectType: { default: "INDEL" }
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_genotyped.vcf", "_raw_indels.vcf.gz"); }
    out: [ output ]
  variant_filtration_indels:
    run: ../../tools/gatk/gatk-VariantFiltration.cwl
    in:
      R: reference_fasta
      V: select_variants_indels/output
      O:
        valueFrom: ${ return inputs.V.nameroot.replace("_raw_indels.vcf", "_filtered_indels.vcf.gz"); }
      filters: indel_filters
    out: [ output ]
