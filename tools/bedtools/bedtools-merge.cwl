#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: bedtools-merge
doc: The bedtools utilities are a swiss-army knife of tools for a wide-range of genomics analysis tasks

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: bedtools-docker.yml
  - $import: bedtools-bioconda.yml

inputs:
  stdout_name:
    type: string
    doc: Stdout from program
  i:
    type: File
    inputBinding:
      position: 1
      prefix: -i
    doc: Input BED format

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.stdout_name)

stdout: $(inputs.stdout_name)

baseCommand: [bedtools, merge]
