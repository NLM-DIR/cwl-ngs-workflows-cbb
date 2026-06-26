#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement

label: "Subsample BAM file creating a tagAlign and pseudoreplicates"
doc: "This workflow creates a subsample from a BAM file creating a tagAlign and pseudoreplicates"

inputs:
    bed_file: File
    nreads: int

outputs:
    tagalign_out:
        outputSource: create_tagalign/output
        type: File
    subsample_out:
        outputSource: gzip/output
        type: File
    pseudoreplicate_gzip_out:
        outputSource: pseudoreplicate_gzip/output
        type: File[]

steps:
    create_tagalign:
        run: create-tagAlign.cwl
        in:
          bed_file: bed_file
        out: [output]
    gzip_cat:
        run: ../../tools/basic/gzip.cwl
        in:
          c: { default: True}
          d: { default: True}
          file: create_tagalign/output
          outFileName:
            valueFrom: ${ return inputs.file.nameroot;}
        out: [output]
    filter_chrM:
       run: ../../tools/basic/grep.cwl
       in:
          v: { default: True }
          outFileName:
            valueFrom: ${ return inputs.file.nameroot;}
          pattern: { default: 'chrM' }
          file: gzip_cat/output
       out: [output]
    shuf:
        run: ../../tools/basic/shuf.cwl
        in:
          n: nreads
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + ".filt.nodup.sample.tagAlign";}
          random-source: gzip_cat/output
          file: filter_chrM/output
        out: [output]
    gzip:
        run: ../../tools/basic/gzip.cwl
        in:
          c: { default: True }
          n: { default: True }
          file: shuf/output
          outFileName:
            valueFrom: ${ return inputs.file.basename + ".gz";}
        out: [output]
    pseudoreplicate_count_lines:
        run: ../../tools/basic/wc.cwl
        in:
          l: { default: True }
          file: gzip_cat/output
          outFileName:
            valueFrom: ${ return inputs.file.nameroot;}
        out: [output]
    pseudoreplicate_split_file:
        run: ../../tools/basic/split_half.cwl
        in:
          d: { default: True}
          valuefile: pseudoreplicate_count_lines/output
          file: gzip_cat/output
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + '.';}
        out: [output]
    pseudoreplicate_gzip:
        run: ../../tools/basic/gzip.cwl
        scatter: [file]
        in:
          c: { default: True }
          file: pseudoreplicate_split_file/output
          outFileName:
            valueFrom: ${ return inputs.file.basename + '.tagAlign.gz';}
        out: [output]
