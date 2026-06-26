#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

label: "Create tagAlign file"
doc: "This workflow creates tagAlign file"

inputs:
    bed_file: File

outputs:
    output:
        outputSource: gzip/output
        type: File

steps:
    awk:
        run: ../../tools/basic/awk.cwl
        in:
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + ".tagAlign";}
          file: bed_file
          text: { default: 'BEGIN{OFS="\t"}{$4="N";$5="1000";print $0}'  }
        out: [output]
    gzip:
       run: ../../tools/basic/gzip.cwl
       in:
          file: awk/output
       out: [output]
