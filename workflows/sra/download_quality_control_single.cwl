class: Workflow
cwlVersion: v1.2
id: download_quality_control
doc: >-
  This workflow download an SRA accession and perform quality control on it
  using FastQC
label: SRA download and QC

requirements:
  InlineJavascriptRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  accession: string
  ncbi_config: Directory
  threads: int
  X: int?
  split-files: boolean?

outputs:
  fastqc_html:
    outputSource: fastqc/out_html
    type: File[]
  fastqc_zip:
    outputSource: fastqc/out_zip
    type: File[]
  fastq:
    outputSource: fastq_dump/output
    type: File[]

steps:
  fastq_dump:
    run: ../../tools/sra-tools/fastq-dump.cwl
    label: fastq-dump
    in:
      ncbi_config: ncbi_config
      accession: accession
      X: X
      gzip: { default: true }
      split-files: split-files
      defline_seq: { default: "@$ac.$si/$ri"}
      defline_qual: { default: "+$ac.$si/$ri"}
      skip_technical: { default: true }
    out: [output]
  fastqc:
    run: ../../tools/fastqc/fastqc.cwl
    label: fastqc
    in:
      fastq: fastq_dump/output
      threads: threads
    out: [out_html, out_zip]
