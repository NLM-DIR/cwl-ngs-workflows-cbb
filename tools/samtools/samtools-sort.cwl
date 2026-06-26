#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-sort
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: $(inputs.threads)

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  threads:
    type: int?
    inputBinding:
      prefix: --threads
      position: 1
  out_bam:
    type: string
    inputBinding:
      position: 2
      prefix: -o
  in_bam:
    type: File
    inputBinding:
      position: 3
  n:
    type: boolean?
    inputBinding:
      prefix: -n
      position: 1

outputs:
  out_sam:
    type: File
    outputBinding:
      glob: $(inputs.out_bam)

baseCommand: [samtools, sort]
