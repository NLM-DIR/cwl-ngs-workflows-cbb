#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: wget
doc: wget command

requirements:
  InlineJavascriptRequirement: {}

hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10

  SoftwareRequirement:
    packages:
      - package: 'gnu-wget'
        version:
          - '1.18'
        specs:
          - https://anaconda.org/bioconda/gnu-wget

inputs:
  O:
    type: string
    inputBinding:
      position: 1
      prefix: -O
  i:
    type: string
    inputBinding:
      position: 2

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.O)
  log:
    type: stdout

stdout: wget-$(inputs.O).log
stderr: wget-$(inputs.O).log

baseCommand: ["wget"]
