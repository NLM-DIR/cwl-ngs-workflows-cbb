#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: sortalign
doc: Sort align maps deep-sequencing files

requirements:
  InlineJavascriptRequirement: {}

inputs:
  wiggle:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --wiggle
    doc: Report target coverage wiggles in UCSC BF (fixed) format
  sam:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --sam
    doc: Output SAM format
  x:
    type: Directory
    inputBinding:
      position: 2
      prefix: -x
    doc: A directory of index files created  previously using --createIndex
  o:
    type: string?
    inputBinding:
      position: 4
      prefix: -o
    doc: Output file name
  input:
    type: File[]
    inputBinding:
      position: 3
      prefix: -i
      valueFrom: |
        ${
          var files = inputs.input;
          var files = files.map(function(f) { return f.path; });
          return files.join("+");
        }
    doc: Input files to sort and align


outputs:
  output:
    type: File[]
    outputBinding:
      glob: $(inputs.o)*

baseCommand: ["sortalign",]