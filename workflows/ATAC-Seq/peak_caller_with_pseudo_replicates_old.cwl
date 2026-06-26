class: Workflow
cwlVersion: v1.0
doc: >-
  This workflow execute peak caller a ATAC-Seq with pseudo samples
label: ATAC-Seq peak caller workflow for single-end samples

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  genome_fasta:
    type: File
  genome_gtf:
    type: File
  bam:
    type: File
    secondaryFiles:
      - .bai
  macs_callpeaks_g:
    type: string
  macs_callpeaks_q:
    type: float
  threads:
    type: int

outputs:
  readQC_plots:
    outputSource: readQC/plots
    type: File[]
  idr_peaks:
    outputSource: idr/idr_peaks
    type: File
  idr_plots:
    outputSource: idr/plots
    type: File[]
  dedup_bam:
    outputSource: remove_duplicates/dedup_bam
    type: File
    secondaryFiles: [ .bai ]
  dedup_metrics:
    outputSource: remove_duplicates/dedup_metrics
    type: File
  dedup_bed:
    outputSource: remove_duplicates/dedup_bed
    type: File
  annotation:
    outputSource: homer_annotate_peaks_file/output
    type: File
  annotation_stats:
    outputSource: homer_annotate_peaks_file/annStats_out
    type: File
  pooled_narrowPeak:
    outputSource: poolled_call_peak/macs_callpeak_q_value_narrowPeak
    type: File
  pseudo_A_narrowPeak:
    outputSource: pseudo_A_call_peak/macs_callpeak_q_value_narrowPeak
    type: File
  pseudo_B_narrowPeak:
    outputSource: pseudo_B_call_peak/macs_callpeak_q_value_narrowPeak
    type: File


steps:
  remove_duplicates:
    run: ../Duplication/remove-duplication-picard.cwl
    in:
      bam: bam
      threads: threads
    out: [dedup_bam, dedup_metrics, dedup_bed]
  create_pseudo_replicates:
    run: ../Pseudo-replicate/create-pseudo-replicates.cwl
    label: Create Pseudo-replicates
    in:
      bam: remove_duplicates/dedup_bam
      seed: { default: 42 }
      threads: threads
    out: [bam_A, bed_A, bam_B, bed_B]
  homer_tags:
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    label: HOMER-makeTagDirectory
    in:
      checkGC: { default: true}
      format: { default: "bed"}
      genome: genome_fasta
      input: remove_duplicates/dedup_bed
      tags_directory_name:
        valueFrom: ${ return inputs.input.nameroot + "_tags_directory";}
    out: [tags_directory]
  poolled_call_peak:
    run: peak_caller-singlecall-PE.cwl
    in:
      input_bam: remove_duplicates/dedup_bam
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [macs_callpeak_q_value_narrowPeak]
  pseudo_A_call_peak:
    run: peak_caller-singlecall-PE.cwl
    in:
      input_bam: create_pseudo_replicates/bam_A
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [ macs_callpeak_q_value_narrowPeak ]
  pseudo_B_call_peak:
    run: peak_caller-singlecall-PE.cwl
    in:
      input_bam: create_pseudo_replicates/bam_B
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [ macs_callpeak_q_value_narrowPeak ]
  readQC:
    run: ../../tools/R/readQC.cwl
    label: readQC
    in:
      tags_directory: homer_tags/tags_directory
    out: [ plots ]
  idr:
    run: ../../tools/idr/idr.cwl
    label: idr
    in:
      input_file_type: { default: "narrowPeak"}
      output_file:
        valueFrom: ${ return inputs.peak_list.nameroot + ".txt";}
      peak_list: poolled_call_peak/macs_callpeak_q_value_narrowPeak
      plot: { default: true }
      rank: { default: "p.value"}
      samples:
        - pseudo_A_call_peak/macs_callpeak_q_value_narrowPeak
        - pseudo_B_call_peak/macs_callpeak_q_value_narrowPeak
      use_best_multisummit_IDR: { default: true }
    out: [ idr_peaks, plots ]
  homer_annotate_peaks_file:
    run: ../../tools/homer/homer-annotatePeaks.cwl
    in:
      annStats:
        valueFrom: ${ return inputs.input.basename + "_annStats.txt";}
      d: homer_tags/tags_directory
      fpkm: { default: true }
      genome: genome_fasta
      gtf: genome_gtf
      input: idr/idr_peaks
      o:
        valueFrom: ${ return inputs.input.basename + "_annotation.txt";}
    out: [ annStats_out, output ]