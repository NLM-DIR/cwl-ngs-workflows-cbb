#!/usr/bin/env cwl-runner
class: CommandLineTool
cwlVersion: v1.2
label: Create FASTA from FASTQ

requirements:
  InlineJavascriptRequirement: { }
  ShellCommandRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  fastq1:
    type: File
    streamable: true
    inputBinding:
      position: 1
  fastq2:
    type: File?
    streamable: true
    inputBinding:
      position: 2
  pipe:
    type: string
    default: "|"
    inputBinding:
      position: 3
      shellQuote: False
  sed:
    type: string
    default: " -n '1~4s/^@/>/p;2~4p'"
    inputBinding:
      position: 4
      prefix: sed
      shellQuote: False

outputs:
  output:
    type: File
    streamable: true
    outputBinding:
      glob: $(inputs.fastq1.nameroot + ".fsa")

stdout: $(inputs.fastq1.nameroot + ".fsa")

baseCommand: [ "zcat" ]
