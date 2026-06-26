class: CommandLineTool
cwlVersion: v1.2

id: fastq_dump
label: fastq-dump
doc: Fastq-dump from SRA database

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.ncbi_config)

hints:
  - $import: sra-tools-docker.yml
  - $import: sra-tools-bioconda.yml

inputs:
  - id: ncbi_config
    type: Directory
  - id: fasta
    type: boolean?
    inputBinding:
      position: 1
      prefix: '--fasta'
    label: fasta
    doc: 'FASTA only, no qualities'
  - id: gzip
    type: boolean?
    inputBinding:
      position: 2
      prefix: '--gzip'
  - id: split-files
    type: boolean?
    inputBinding:
      position: 3
      prefix: '--split-files'
  - id: X
    type: int?
    inputBinding:
      position: 4
      prefix: '-X'
  - id: aligned
    type: boolean?
    inputBinding:
      position: 5
      prefix: '--aligned'
  - id: defline_seq
    type: string
    inputBinding:
      position: 6
      prefix: '--defline-seq'
  - id: defline_qual
    type: string?
    inputBinding:
      position: 7
      prefix: '--defline-qual'
  - id: read_filter
    type: string?
    inputBinding:
      position: 8
      prefix: '--read-filter'
  - id: skip_technical
    type: boolean?
    inputBinding:
      position: 9
      prefix: '--skip-technical'
  - id: accession
    type: string
    inputBinding:
      position: 10
    label: accession
    doc: SRA accession ID
outputs:
  - id: output
    type: 'File[]'
    outputBinding:
      glob: $(inputs.accession)*

baseCommand:
  - fastq-dump
