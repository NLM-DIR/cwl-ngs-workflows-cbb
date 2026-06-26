#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-markdup
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
      position: 3
  in_bam:
    type: File
    inputBinding:
      position: 2
  r:
    type: boolean?
    inputBinding:
      prefix: -r
      position: 1

outputs:
  out:
    type: File
    outputBinding:
      glob: $(inputs.out_bam)

baseCommand: [samtools, markdup]
