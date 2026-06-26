#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-flagstat
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  stdout:
    type: string
  in_bam:
    type: File
    inputBinding:
      position: 1

outputs:
  out_stdout:
    type: File
    outputBinding:
      glob: $(inputs.stdout)

stdout: $(inputs.stdout)

baseCommand: [samtools, flagstat]
