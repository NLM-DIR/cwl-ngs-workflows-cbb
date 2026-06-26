#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: bgzip
doc: Compress files

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: --threads
  o:
    type: string
    inputBinding:
      position: 2
      prefix: -o
  i:
    type: File
    inputBinding:
      position: 3

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.o)

baseCommand: [bgzip]
