class: CommandLineTool
cwlVersion: v1.2

label: gatk-CombineGVCFs
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  InlineJavascriptRequirement: {}

inputs:
  variants:
    type: File[]
    inputBinding:
      position: 3
      prefix: --variant
  R:
    type: File
    secondaryFiles: [.fai, ^.dict]
    inputBinding:
      position: 4
      prefix: -R
  O:
    type: string
    inputBinding:
      position: 5
      prefix: -O
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "CombineGVCFs"
    inputBinding:
      position: 2
      shellQuote: False

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.O)

baseCommand: [gatk]
