class: CommandLineTool
cwlVersion: v1.2

doc: BASH echo command
label: FastQC

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
      coresMin: $(inputs.threads)

hints:
  - $import: fastqc-docker.yml
  - $import: fastqc-bioconda.yml

inputs:
  fastq:
    type: File[]
    inputBinding:
      position: 2
  threads:
    type: int
    inputBinding:
      position: 1
      prefix: '-t'
outputs:
  out_html:
    type: File[]
    outputBinding:
      glob: '*.html'
  out_zip:
    type: File[]
    outputBinding:
      glob: '*.zip'

baseCommand: ["fastqc", "--outdir", ".", "--extract"]
