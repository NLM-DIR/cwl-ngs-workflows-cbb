#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-merge
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: -@
    doc: |
      number of BAM compression threads [0]
  out_bam:
    type: string
    inputBinding:
      position: 2
  in_bam:
    type: File[]
    inputBinding:
      position: 3
      separate: true
      itemSeparator: " "
      shellQuote: false

outputs:
  out_sam:
    type: File
    outputBinding:
      glob: $(inputs.out_bam)

baseCommand: [samtools, merge]
