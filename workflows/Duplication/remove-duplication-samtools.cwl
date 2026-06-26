class: Workflow
cwlVersion: v1.2

id: remove-duplication-samtools
doc: Remove duplicated reads with Samtools
label: Remove duplicated reads with Samtools

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  bam: File
  threads: int

outputs:
  dedup_bam:
    outputSource: dedup_index_bam/out_sam
    type: File
    secondaryFiles: [ .bai ]
  dedup_metrics:
    outputSource: dedup_bam_flagstag/out_stdout
    type: File
  dedup_bed:
    outputSource: bamtobed/out_stdout
    type: File

steps:
  sort_name:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: bam
      n: { default: True }
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot.replace("_sorted", "_named.bam");}
      threads: threads
    out: [ out_sam ]
  fixmate:
    run: ../../tools/samtools/samtools-fixmate.cwl
    label: Samtools-fixmate
    in:
      in_bam: sort_name/out_sam
      m: { default: True }
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot.replace("_named", "_fixmate.bam");}
      threads: threads
    out: [ out ]
  sort_name_fixmate:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: fixmate/out
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam";}
      threads: threads
    out: [ out_sam ]
  markdup:
    run: ../../tools/samtools/samtools-markdup.cwl
    label: Samtools-markdup
    in:
      in_bam: sort_name_fixmate/out_sam
      r: { default: True }
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_markdup.bam";}
      threads: threads
    out: [ out ]
  markdup_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: markdup/out
    out: [ out_sam ]
  filtering:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: markdup_index/out_sam
      isbam: { default: true }
      output_name:
        valueFrom: ${ return inputs.input.nameroot.replace("_fixmate_sorted_markdup", "_dedup.bam");}
      readswithbits: { default: '0x2' }
      readswithoutbits: { default: '0x904' }
    out: [ output ]
  sort_coord_proper:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: filtering/output
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam";}
      threads: threads
    out: [ out_sam ]
  dedup_index_bam:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: sort_coord_proper/out_sam
    out: [ out_sam ]
  dedup_bam_flagstag:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: dedup_index_bam/out_sam
      stdout:
        valueFrom: ${ return inputs.in_bam.nameroot + ".flagstat";}
    out: [ out_stdout ]
  bamtobed:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    in:
      i: dedup_index_bam/out_sam
      bedpe: { default: True }
      stdout:
        valueFrom: ${ return inputs.i.nameroot + ".bed";}
    out: [ out_stdout ]