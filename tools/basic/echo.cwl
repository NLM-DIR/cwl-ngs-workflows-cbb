#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: echo
doc: BASH echo command

inputs:
  stdout:
    type: string
  msg:
    type: string
    inputBinding:
      position: 1

outputs:
  out_stdout:
    type: stdout

stdout: $(inputs.stdout)

baseCommand: ["echo"]
