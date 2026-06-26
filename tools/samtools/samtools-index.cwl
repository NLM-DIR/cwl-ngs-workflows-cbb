#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-index
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.in_bam)

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  in_bam:
    type: File
    inputBinding:
      position: 1

outputs:
  out_sam:
    type: File
    secondaryFiles: [ .bai ]
    outputBinding:
      glob: $(inputs.in_bam.basename)

baseCommand: [samtools, index, -b]
