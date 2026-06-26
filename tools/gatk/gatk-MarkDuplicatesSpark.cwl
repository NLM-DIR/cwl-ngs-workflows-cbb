class: CommandLineTool
cwlVersion: v1.2

label: gatk-MarkDuplicatesSpark
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

inputs:
  I:
    type: File
    inputBinding:
      position: 3
      prefix: -I
  O:
    type: string
    inputBinding:
      position: 4
      prefix: -O
  M:
    type: string?
    inputBinding:
      position: 5
      prefix: -M
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "MarkDuplicatesSpark"
    inputBinding:
      position: 2
      shellQuote: False

outputs:
  output:
    type: File
    secondaryFiles: [.bai, .sbi]
    outputBinding:
      glob: $(inputs.O)
  metrics:
    type: File
    outputBinding:
      glob: $(inputs.M)

baseCommand: [gatk]
