class: Workflow
cwlVersion: v1.2

id: chip_seq_alignment
doc: This workflow aligns ChIp-Seq samples
label: ChIP-Seq alignment workflow

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  all: boolean?
  k: int?
  very_sensitive: boolean?
  bowtie_index:
    type: File
    secondaryFiles:
      - .1.bt2
      - .2.bt2
      - .3.bt2
      - .4.bt2
      - .rev.1.bt2
      - .rev.2.bt2
  reads:
    type: {"type": "array", "items": {"type": "array", "items": "File"}}
  readsquality: int
  subsample_nreads: int
  threads: int

outputs:
  bam_flagstat_out:
    outputSource: alignment/bam_flagstat_out
    type: File[]
  bam_index_out:
    outputSource: bam_index/out_sam
    type: File[]
  bam_stats_out:
    outputSource: alignment/bam_stats_out
    type: File[]
  bed_file_out:
    outputSource: bamtobed/out_stdout
    type: File[]
  final_bam_flagstat_out:
    outputSource: final_bam_flagstat/out_stdout
    type: File[]
  final_bam_out:
    outputSource: final_bam/out_sam
    type: File[]
  pbc_out:
    outputSource: pbc/out
    type: File[]
  phantompeakqualtools_output_out:
    outputSource: phantompeakqualtools/output_out
    type: File[]
  phantompeakqualtools_output_savp:
    outputSource: phantompeakqualtools/output_savp
    type: File[]?
  subsample_pseudoreplicate_gzip_out:
    outputSource: subsample/pseudoreplicate_gzip_out
    type: {"type": "array", "items": {"type": "array", "items": "File"}}
  subsample_subsample_out:
    outputSource: subsample/subsample_out
    type: File[]
  subsample_tagalign_out:
    outputSource: subsample/tagalign_out
    type: File[]

steps:
  alignment:
    run: bowtie-alignment.cwl
    label: bwa alignment workflow for single-end samples
    scatter: reads
    in:
      reads: reads
      bowtie_index: bowtie_index
      very_sensitive: very_sensitive
      all: all
      k: k
      threads: threads
    out: [bam_out, bam_flagstat_out, bam_stats_out]
  filtered_bam:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    scatter: input
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
    scatter: in_bam
    in:
      in_bam: filtered_bam/output
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_sorted.bam";}'
      threads: threads
    out: [ out_sam ]
  bam_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    scatter: in_bam
    in:
      in_bam: final_bam/out_sam
    out: [out_sam]
  bamtobed:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    scatter: i
    in:
      i: final_bam/out_sam
      stdout:
        valueFrom: '${ return inputs.i.nameroot + ".bed";}'
    out: [out_stdout]
  final_bam_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    scatter: in_bam
    in:
      in_bam: final_bam/out_sam
      stdout:
        valueFrom: >-
          ${ return
          inputs.in_bam.nameroot.replace("_sorted","_filtered.flagstat")}
    out: [out_stdout]
  pbc:
    run: ../File-formats/bedtools-bam-pbc.cwl
    label: Compute library complexity
    scatter: bed_file
    in:
      bed_file: bamtobed/out_stdout
    out: [out]
  subsample:
    run: ../File-formats/subample-pseudoreplicates.cwl
    label: Subsample BAM file creating a tagAlign and pseudoreplicates
    scatter: bed_file
    in:
      bed_file: bamtobed/out_stdout
      nreads: subsample_nreads
    out: [ pseudoreplicate_gzip_out, subsample_out, tagalign_out ]
  phantompeakqualtools:
    run: ../../tools/phantompeakqualtools/phantompeakqualtools.cwl
    label: Phantompeakqualtools
    scatter: c
    in:
      c: subsample/tagalign_out
      filtchr: {default: chrM}
      out:
        valueFrom: '${ return inputs.c.nameroot + ".cc.qc";}'
      p: {default: 5}
      savp:
        valueFrom: '${ return inputs.c.nameroot + ".cc.plot.pdf";}'
    out: [output_out, output_savn, output_savp, output_savr]
