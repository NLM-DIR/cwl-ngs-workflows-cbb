#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: ExpressionTool

label: csvcolumn2list
doc: Read a CSV table in a file and one column in a list

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  file:
    type: File
    inputBinding:
      loadContents: true

outputs:
  output:
    type: string[]

expression:
  "${
      var lines = inputs.file.contents.split('\\n');
      var strings = [];
      for (var i = 0; i < lines.length; i++) {
        if (lines[i] != ''){
          strings.push(lines[i]);
        }
      }
      return { 'output': strings } ;
  }"
