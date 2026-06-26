#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: bc
doc: BC command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  file:
    type: File
    inputBinding:
      position: 2
  outFileName:
    type: string

outputs:
  output:
    type: stdout

stdout: $(inputs.outFileName)

baseCommand: ["sort"]
