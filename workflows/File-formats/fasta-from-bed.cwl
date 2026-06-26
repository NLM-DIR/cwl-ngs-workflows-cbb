#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}

label: "Creates FASTA file from BED coordinates"
doc: "This workflow creates FASTA file from BED coordinates"

inputs:
    fasta: File
    bed: File
    fasta_out: string

outputs:
    output:
        outputSource: samtools_faidx/output
        type: File

steps:
    remove_comments:
        run: ../../tools/basic/grep.cwl
        in:
          v: {default: True}
          pattern: {default: '^#'}
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + ".grep";}
          file: bed
        out: [output]
    bedtocoord:
        run: ../../tools/basic/awk.cwl
        in:
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + ".coord";}
          file: remove_comments/output
          text: { default: '{printf("%s:%d-%d\n",$1,$2,$3)}'}
        out: [output]
    sort:
        run: ../../tools/basic/sort.cwl
        in:
          u: { default: True}
          outFileName:
            valueFrom: ${ return inputs.file.nameroot + ".sort";}
          file: bedtocoord/output
        out: [output]
    samtools_faidx:
        run: ../../tools/samtools/samtools-faidx.cwl
        in:
          o: fasta_out
          input: fasta
          r: sort/output
        out: [output]
