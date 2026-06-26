class: CommandLineTool
cwlVersion: v1.2

id: fasterq_dump
label: fasterq_dump
doc: Faster Fastq-dump from SRA database

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.ncbi_config)

hints:
  - $import: sra-tools-docker.yml
  - $import: sra-tools-bioconda.yml

inputs:
  ncbi_config:
    type: Directory
  accession:
    type: string
    inputBinding:
      position: 2
  S:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -S
  e:
    type: int?
    inputBinding:
      position: 1
      prefix: -e

outputs:
  output:
    type: 'File[]'
    outputBinding:
      glob: $(inputs.accession)*

baseCommand: ["fasterq-dump"]
