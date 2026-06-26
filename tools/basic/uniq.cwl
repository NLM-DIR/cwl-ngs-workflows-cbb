#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: uniq
doc: UNIQ command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  c:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -c
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

baseCommand: ["uniq"]
