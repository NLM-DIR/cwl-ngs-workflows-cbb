#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: awk
doc: AWK command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  F:
    type: string?
    doc: Awk separator
    inputBinding:
      position: 1
      prefix: -F

  text:
    type: string
    doc: Awk text
    inputBinding:
      position: 2
  file:
    type: File
    doc: Input file
    inputBinding:
      position: 3
  outFileName:
    type: string
    doc: Out put file name

outputs:
  output:
    type: stdout

stdout: $(inputs.outFileName)

baseCommand: ["awk"]
