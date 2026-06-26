#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Rename
doc: CAT command

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  input_file:
    type: File
    inputBinding:
      position: 1
  output_filename:
    type: string
    doc: Out put file name

outputs:
  output:
    type: stdout

stdout: $(inputs.output_filename)

baseCommand: ["cat"]
