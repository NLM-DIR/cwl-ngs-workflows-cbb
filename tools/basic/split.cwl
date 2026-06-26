#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: split
doc: SPLIT command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  a:
    type: string?
    inputBinding:
      position: 1
      prefix: -a
  b:
    type: int?
    inputBinding:
      position: 1
      prefix: -b
  C:
    type: int?
    inputBinding:
      position: 1
      prefix: -C
  d:
    type: boolean?
    inputBinding:
      position: 2
      prefix: -d
  numeric-suffixes:
    type: int?
    inputBinding:
      position: 1
      prefix: --numeric-suffixes
  l:
    type: int?
    inputBinding:
      position: 1
      prefix: -l
  t:
    type: string?
    inputBinding:
      position: 1
      prefix: -t
  file:
    type: File
    inputBinding:
      position: 2
  outFileName:
    type: string
    inputBinding:
      position: 3

outputs:
  output:
    type: File[]
    outputBinding:
      glob: $(inputs.outFileName)*

baseCommand: ["split"]
