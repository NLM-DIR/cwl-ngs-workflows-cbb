cwlVersion: v1.0
class: CommandLineTool

label: Deduplicate Bismark
doc: Bismark is a program to map bisulfite

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: bismark-docker.yml
  - $import: bismark-bioconda.yml

inputs:
  single:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --single
  paired:
    type: boolean?
    inputBinding:
      position: 2
      prefix: --paired
  barcode:
    type: boolean?
    inputBinding:
      position: 3
      prefix: --barcode
  outfile:
    type: string
    inputBinding:
      position: 4
      prefix: --outfile
  input:
    type: File
    inputBinding:
      position: 5

outputs:
  bam:
    type: File
    outputBinding:
      glob: $(inputs.outfile).deduplicated.bam
  report:
    type: File
    outputBinding:
      glob: $(inputs.outfile)*_report.txt

baseCommand: ["deduplicate_bismark"]
