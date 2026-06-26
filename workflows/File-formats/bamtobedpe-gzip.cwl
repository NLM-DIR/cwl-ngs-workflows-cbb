#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

label: "BAM to BEDPE"
doc: "Comvert BAM to BEDPE and compress the output"

inputs:
  bam:
    type: File
    doc: BAM file to be analyzed

outputs:
  out:
    type: File
    outputSource: gzip/output

steps:
  bamtobed:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    in:
      stdout:
        valueFrom: ${ return inputs.i.nameroot + ".bedpe";}
      i: bam
      bedpe: { default: True }
    out: [out_stdout]
  gzip:
    run: ../../tools/basic/gzip.cwl
    in:
      file: bamtobed/out_stdout
    out: [output]
