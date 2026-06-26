#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

label: "ChIP-seq peak caller workflow MACS2 based"
doc: "This workflow execute peak caller and QC for ChIP-seq using MACS2"

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  genome_fasta: File
  genome_gtf: File
  tagAlign_gz: File[]
  macs_callpeaks_g: string
  macs_callpeaks_q: float
  nomodel: boolean?
  extsize: int?

outputs:
  readQC_plots:
    outputSource: readQC/plots
    type: {"type": "array", "items": {"type": "array", "items": "File"}}
  macs_cutoff_pdf:
    outputSource: macs_cutoff/out_pdf
    type: File[]
  macs_cutoff_inflection:
    outputSource: macs_cutoff/out_inflection
    type: File[]
  macs_callpeak_q_value_narrowPeak:
    outputSource: macs_callpeak_q_value/narrowPeak
    type: File[]
  macs_callpeak_q_value_xls:
    outputSource: macs_callpeak_q_value/xls
    type: File[]
  macs_callpeak_q_value_bed:
    outputSource: macs_callpeak_q_value/bed
    type: File[]
  homer_annotate_peaks_output:
    outputSource: homer_annotate_peaks/output
    type: File[]
  homer_annotate_peaks_annStats:
    outputSource: homer_annotate_peaks/annStats_out
    type: File[]?
  lambda_tdf_out:
    outputSource: macs_callpeak_q_value/lambda
    type: File[]
  pileup_tdf_out:
    outputSource: macs_callpeak_q_value/pileup
    type: File[]

steps:
  gzip_cat:
    run: ../../tools/basic/gzip.cwl
    scatter: file
    in:
      d: { default: True}
      file: tagAlign_gz
    out: [output]
  homer_tags:
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    scatter: input
    in:
      tags_directory_name:
        valueFrom: ${ return inputs.input.nameroot + "_tags";}
      checkGC: { default: True}
      genome: genome_fasta
      input: gzip_cat/output
      format: { default: "bed"}
    out: [tags_directory]
  readQC:
    run: ../../tools/R/readQC.cwl
    scatter: tags_directory
    in:
      tags_directory: homer_tags/tags_directory
    out: [plots]
  macs_callpeak:
    run: ../../tools/macs/macs2-callpeak.cwl
    scatter: t
    in:
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      f: { default: "BED"}
      g: macs_callpeaks_g
      cutoff-analysis: { default: True}
      nomodel: nomodel
      B: { default: True}
      shift: { default: 0}
      extsize: extsize
      q: macs_callpeaks_q
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_peaks";}
      t: gzip_cat/output
    out: [cutoff_analysis]
  macs_cutoff:
    run: ../../tools/R/macs-cutoff.cwl
    scatter: peak_cutoff_file
    in:
      peak_cutoff_file: macs_callpeak/cutoff_analysis
      out_pdf_name:
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + ".pdf";}
      out_inflection_name:
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + "_inflection.txt";}
    out: [out_pdf,out_inflection]
  macs_callpeak_q_value:
    run: ../../tools/macs/macs2-callpeak.cwl
    scatter: [t, q_file]
    scatterMethod: dotproduct
    in:
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      f: { default: "BED"}
      g: macs_callpeaks_g
      cutoff-analysis: { default: True}
      call-summits: { default: True}
      nomodel: nomodel
      B: { default: True}
      shift: { default: 0}
      extsize: extsize
      q_file: macs_cutoff/out_inflection
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_peaks";}
      t: gzip_cat/output
    out: [lambda, pileup, narrowPeak, xls, bed]
  homer_annotate_peaks:
    run: ../../tools/homer/homer-annotatePeaks.cwl
    scatter: [input, d]
    scatterMethod: dotproduct
    in:
      genome: genome_fasta
      gtf: genome_gtf
      input: macs_callpeak_q_value/narrowPeak
      o:
        valueFrom: ${ return inputs.input.nameroot + "_annotation.txt";}
      annStats:
        valueFrom: ${ return inputs.input.nameroot + "_annStats.txt";}
      d: homer_tags/tags_directory
      fpkm: {default: True}
    out: [output,annStats_out]
