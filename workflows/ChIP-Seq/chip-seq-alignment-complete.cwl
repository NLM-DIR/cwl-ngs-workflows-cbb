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
  bed_file_out:
    outputSource: bamtobed/out_stdout
    type: File
  final_bam_flagstat_out:
    outputSource: final_bam_flagstat/out_stdout
    type: File
  final_bam_out:
    outputSource: final_bam/out_sam
    type: File
  pbc_out:
    outputSource: pbc/out
    type: File
  phantompeakqualtools_output_out:
    outputSource: phantompeakqualtools/output_out
    type: File
  phantompeakqualtools_output_savp:
    outputSource: phantompeakqualtools/output_savp
    type: File
  tagalign_out:
    outputSource: create_tagalign/output
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
  sort_name:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    scatter: in_bam
    in:
      in_bam: bam_index/out_sam
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
  pbc:
    run: ../File-formats/bedtools-bam-pbc.cwl
    label: Compute library complexity
    in:
      bed_file: bamtobed/out_stdout
    out: [out]
  create_tagalign:
    run: ../File-formats/create-tagAlign.cwl
    in:
      bed_file: bamtobed/out_stdout
    out: [ output ]
  phantompeakqualtools:
    run: ../../tools/phantompeakqualtools/phantompeakqualtools.cwl
    label: Phantompeakqualtools
    in:
      c: create_tagalign/output
      filtchr: {default: chrM}
      out:
        valueFrom: '${ return inputs.c.nameroot + ".cc.qc";}'
      p: {default: 5}
      savp:
        valueFrom: '${ return inputs.c.nameroot + ".cc.plot.pdf";}'
    out: [output_out, output_savn, output_savp, output_savr]
