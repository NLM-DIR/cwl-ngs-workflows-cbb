#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: extract_file_from_directory
doc: Extract file from directory

requirements:
  InlineJavascriptRequirement: {}

hints:
  LoadListingRequirement:
    loadListing: no_listing

inputs:
  d:
    type: Directory
    inputBinding:
      position: 1
      valueFrom: ${ return self.path + '/' + inputs.filename;}
  filename:
    type: string
  o:
    type: string
    inputBinding:
      position: 2
    doc: |
      Out file name

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.o)

baseCommand: ["cp"]
