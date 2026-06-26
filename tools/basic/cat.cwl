#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: cat
doc: CAT command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  files:
    type: File[]
    inputBinding:
      position: 1
  outFileName:
    type: string
    doc: Out put file name

outputs:
  output:
    type: stdout

stdout: $(inputs.outFileName)

baseCommand: ["cat"]
