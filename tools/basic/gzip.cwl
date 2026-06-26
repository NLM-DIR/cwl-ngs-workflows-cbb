#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: gzip
doc: Compress files

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  d:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -d
  file:
    type: File
    inputBinding:
      position: 2

outputs:
  output:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.d){
            return inputs.file.nameroot;
          }else{
            return inputs.file.basename + '.gz';
          }
        }
      
stdout: |
    ${
        if (inputs.d){
            return inputs.file.nameroot;
        }else{
            return inputs.file.basename + '.gz';
        }
    }

baseCommand: ["gzip", "-c"]
