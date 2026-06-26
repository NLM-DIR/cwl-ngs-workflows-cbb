class: Workflow
cwlVersion: v1.2
doc: >-
  This workflow remove duplicates and create psueduoreplicates
label: Remove duplicates and create psueduoreplicates

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  genome_fasta:
    type: File
  bam:
    type: File
    secondaryFiles:
      - .bai
  threads:
    type: int
  pseudo_replicates:
    type: boolean?
    default: false
  assay_type:
    type:
      type: enum
      symbols: [ chipseq, atacseq ]
    default: chipseq
  readsquality:
    type: int
    default: 30

outputs:
  dedup_bam:
    outputSource: remove_duplicates/dedup_bam
    type: File
    secondaryFiles: [ .bai ]
  dedup_metrics:
    outputSource: remove_duplicates/dedup_metrics
    type: File
  dedup_flagstat:
    outputSource: remove_duplicates/dedup_flagstat
    type: File
  pseudo_A_bam:
    outputSource: create_pseudo_replicates/bam_A
    type: File?
  pseudo_B_bam:
    outputSource: create_pseudo_replicates/bam_B
    type: File?
  homer_tag_directory:
    outputSource: homer_tags/tags_directory
    type: Directory?
  readQC_plots:
    outputSource: readQC/plots
    type: File[]?

steps:
  remove_duplicates:
    run: ../Duplication/remove-duplication-picard.cwl
    in:
      bam: bam
      assay_type: assay_type
      readsquality: readsquality
      threads: threads
    out: [dedup_bam, dedup_metrics, dedup_flagstat, dedup_bed]
  create_pseudo_replicates:
    when: $(inputs["pseudo_replicates"])
    run: ../Pseudo-replicate/create-pseudo-replicates.cwl
    label: Create Pseudo-replicates
    in:
      pseudo_replicates: pseudo_replicates
      bam: remove_duplicates/dedup_bam
      seed: { default: 42 }
      threads: threads
    out: [bam_A, bed_A, bam_B, bed_B]
  homer_tags:
    when: $(inputs["pseudo_replicates"])
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    label: HOMER-makeTagDirectory
    in:
      pseudo_replicates: pseudo_replicates
      checkGC: { default: true }
      format: { default: "sam" }
      genome: genome_fasta
      input: remove_duplicates/dedup_bam
      tags_directory_name:
        valueFrom: ${ return inputs.input.nameroot + "_tags_directory";}
    out: [ tags_directory ]
  readQC:
    when: $(inputs["pseudo_replicates"])
    run: ../../tools/R/readQC.cwl
    label: readQC
    in:
      pseudo_replicates: pseudo_replicates
      tags_directory: homer_tags/tags_directory
    out: [ plots ]
