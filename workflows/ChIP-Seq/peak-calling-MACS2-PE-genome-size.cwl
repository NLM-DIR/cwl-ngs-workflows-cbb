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
  bams: File[]
  macs_callpeaks_g: string
  macs_callpeaks_q: float
  nomodel: boolean?
  extsize: int?
  threads: int?

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
  bamtobed_tagAlign:
    outputSource: bamtobed/out_stdout
    type: File[]
  proper_bam_out:
    outputSource: proper_bam/out_sam
    type: File[]
  proper_bam_flagstat:
    outputSource: proper_flagstat/out_stdout
    type: File[]

steps:
  sort_name:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    scatter: in_bam
    in:
      in_bam: bams
      n: { default: True }
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot.replace("_sorted", "_named.bam");}'
      threads: threads
    out: [ out_sam ]
  fixmate:
    run: ../../tools/samtools/samtools-fixmate.cwl
    label: Samtools-fixmate
    scatter: in_bam
    in:
      in_bam: sort_name/out_sam
      m: { default: True }
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot.replace("_named", "_fixmate.bam");}'
      threads: threads
    out: [ out ]
  sort_name_fixmate:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    scatter: in_bam
    in:
      in_bam: fixmate/out
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_sorted.bam";}'
      threads: threads
    out: [ out_sam ]
  markdup:
    run: ../../tools/samtools/samtools-markdup.cwl
    label: Samtools-markdup
    scatter: in_bam
    in:
      in_bam: sort_name_fixmate/out_sam
      r: { default: True }
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_markdup.bam";}'
      threads: threads
    out: [ out ]
  markdup_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    scatter: in_bam
    in:
      in_bam: markdup/out
    out: [ out_sam ]
  filtering:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    scatter: input
    in:
      input: markdup_index/out_sam
      isbam: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + "_proper.bam";}'
      readswithbits: { default: '0x2' }
      readswithoutbits: { default: '0x904' }
    out: [ output ]
  proper_bam:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    scatter: in_bam
    in:
      in_bam: filtering/output
    out: [ out_sam ]
  proper_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    scatter: in_bam
    in:
      in_bam: proper_bam/out_sam
      stdout:
        valueFrom: '${ return inputs.in_bam.nameroot + ".flagstat";}'
    out: [ out_stdout ]
  bamtobed:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    scatter: i
    in:
      i: proper_bam/out_sam
      bedpe: { default: True }
      stdout:
        valueFrom: '${ return inputs.i.nameroot + ".bed";}'
    out: [ out_stdout ]
  tagAlign:
    run: ../../tools/basic/awk.cwl
    scatter: file
    in:
      outFileName:
        valueFrom: ${ return inputs.file.nameroot + ".tagAlign";}
      file: bamtobed/out_stdout
      text: { default: 'BEGIN{OFS="\t"} ($1==$4) { s = ($2<$5)?$2:$5; e = ($3>$6)?$3:$6; L = e - s; if (L>0 && L<1000) { print $1,s,e,"N",1000,$9 }}' }
    out: [ output ]
  homer_tags:
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    scatter: input
    in:
      tags_directory_name:
        valueFrom: ${ return inputs.input.nameroot + "_tags";}
      checkGC: { default: True}
      genome: genome_fasta
      input: tagAlign/output
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
      f: { default: "BAMPE"}
      g: macs_callpeaks_g
      cutoff-analysis: { default: True}
      nomodel: nomodel
      B: { default: True}
      shift: { default: 0}
      extsize: extsize
      q: macs_callpeaks_q
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_peaks";}
      t: proper_bam/out_sam
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
      f: { default: "BAMPE"}
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
      t: proper_bam/out_sam
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
