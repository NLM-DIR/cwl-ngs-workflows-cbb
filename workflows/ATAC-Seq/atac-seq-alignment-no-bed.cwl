class: Workflow
cwlVersion: v1.2

id: atac_seq_alignment
doc: This workflow aligns ATAC-Seq samples
label: ATAC-Seq alignment workflow

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  bwa_k: int?
  bwa_c: int?
  bwa_T: int?
  bwa_R: string?
  genome_index: Directory
  genome_prefix: string
  reads: File[]
  readsquality: int
  threads: int

outputs:
  bam_flagstat_out:
    outputSource: alignment/bam_flagstat_out
    type: File
  bam_out:
    outputSource: bam_index/out_sam
    type: File
    secondaryFiles: [ .bai ]
  bam_stats_out:
    outputSource: alignment/bam_stats_out
    type: File
  final_bam_flagstat_out:
    outputSource: final_bam_flagstat/out_stdout
    type: File
  final_bam_out:
    outputSource: final_bam/out_sam
    type: File

steps:
  alignment:
    run: ../Alignments/bwa-alignment.cwl
    label: bwa alignment workflow for single-end samples
    in:
      reads: reads
      genome_index: genome_index
      genome_prefix: genome_prefix
      threads: threads
      bwa_k: bwa_k
      bwa_c: bwa_c
      bwa_T: bwa_T
      bwa_R: bwa_R
    out: [bam_out, bam_flagstat_out, bam_stats_out]
  filtered_bam:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: alignment/bam_out
      isbam: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".bam";}'
      readsquality: readsquality
      threads: threads
    out: [ output ]
  final_bam:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: filtered_bam/output
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_sorted.bam";}'
      threads: threads
    out: [ out_sam ]
  bam_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: final_bam/out_sam
    out: [out_sam]
  final_bam_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: final_bam/out_sam
      stdout:
        valueFrom: >-
          ${ return
          inputs.in_bam.nameroot.replace("_sorted","_filtered.flagstat")}
    out: [out_stdout]
