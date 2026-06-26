class: Workflow
cwlVersion: v1.2
doc: >-
  This workflow execute peak caller a ATAC-Seq with pseudo samples
label: ATAC-Seq peak caller workflow for single-end samples

requirements:
  InlineJavascriptRequirement: { }
  StepInputExpressionRequirement: { }
  SubworkflowFeatureRequirement: { }
  ScatterFeatureRequirement: { }
  MultipleInputFeatureRequirement: { }

inputs:
  genome_fasta:
    type: File
  genome_gtf:
    type: File
  homer_tag_directory:
    type: Directory
  bam:
    type: File
    secondaryFiles:
      - .bai
  bam_flagstat:
    type: File
  bam_A:
    type: File
    secondaryFiles:
      - .bai
  bam_B:
    type: File
    secondaryFiles:
      - .bai
  macs_callpeaks_g:
    type: string
  macs_callpeaks_q:
    type: float
  threads:
    type: int
  cutoff-analysis:
    type: boolean?

outputs:
  idr_peaks:
    outputSource: idr/idr_peaks
    type: File?
  idr_plots:
    outputSource: idr/plots
    type: File[]?
  annotation:
    outputSource: homer_annotate_peaks_file/output
    type: File?
  annotation_stats:
    outputSource: homer_annotate_peaks_file/annStats_out
    type: File?
  pooled_narrowPeak:
    outputSource: poolled_call_peak/narrowPeak
    type: File?
  pseudo_A_narrowPeak:
    outputSource: pseudo_A_call_peak/narrowPeak
    type: File?
  pseudo_B_narrowPeak:
    outputSource: pseudo_B_call_peak/narrowPeak
    type: File?


steps:
  poolled_call_peak:
    run: peak_caller.cwl
    in:
      bam: bam
      bam_flagstat: bam_flagstat
      cutoff-analysis: cutoff-analysis
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [ narrowPeak ]
  pseudo_A_call_peak:
    run: peak_caller.cwl
    in:
      bam: bam_A
      bam_flagstat: bam_flagstat
      cutoff-analysis: cutoff-analysis
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [ narrowPeak ]
  pseudo_B_call_peak:
    run: peak_caller.cwl
    in:
      bam: bam_B
      bam_flagstat: bam_flagstat
      cutoff-analysis: cutoff-analysis
      macs_callpeaks_g: macs_callpeaks_g
      macs_callpeaks_q: macs_callpeaks_q
    out: [ narrowPeak ]
  idr:
    run: ../../tools/idr/idr.cwl
    label: idr
    in:
      input_file_type: { default: "narrowPeak" }
      output_file:
        valueFrom: |
          ${ return inputs.peak_list ? inputs.peak_list.nameroot + "_idr_peaks" : null;}
      peak_list: poolled_call_peak/narrowPeak
      plot: { default: true }
      rank: { default: "p.value" }
      samples:
        - pseudo_A_call_peak/narrowPeak
        - pseudo_B_call_peak/narrowPeak
      use_best_multisummit_IDR: { default: true }
    out: [ idr_peaks, plots ]
  homer_annotate_peaks_file:
    run: ../../tools/homer/homer-annotatePeaks.cwl
    in:
      annStats:
        valueFrom: |
          ${ return inputs.input ? inputs.input.nameroot + "_annStats.txt": null;}
      d: homer_tag_directory
      fpkm: { default: true }
      genome: genome_fasta
      gtf: genome_gtf
      input: idr/idr_peaks
      o:
        valueFrom: |
          ${ return inputs.input ? inputs.input.nameroot + "_annotation.txt" : null;}
    out: [ annStats_out, output ]
