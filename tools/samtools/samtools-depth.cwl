#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-depth
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  o:
    type: string
  a:
    type: File
    inputBinding:
      position: 1
      prefix: -a

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.o)

stdout: $(inputs.o)

baseCommand: [samtools, depth]
