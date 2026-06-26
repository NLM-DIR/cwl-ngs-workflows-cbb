class: CommandLineTool
cwlVersion: v1.2

label: gatk-AnalyzeCovariates
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

inputs:
  before:
    type: File
    inputBinding:
      position: 1
      prefix: -before
  after:
    type: File
    inputBinding:
      position: 2
      prefix: -after
  plots:
    type: string
    inputBinding:
      position: 3
      prefix: -plots

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.plots)

baseCommand: [gatk, AnalyzeCovariates]
