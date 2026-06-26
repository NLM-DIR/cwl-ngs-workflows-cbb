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
    outputSource: gzip_file/output
    type: File[]

steps:
  fasterq_dum:
    run: ../../tools/sra-tools/fasterq-dump.cwl
    label: fasterq-dump-SE
    in:
      ncbi_config: ncbi_config
      accession: accession
      S: split-files
      e: threads
    out: [ output ]
  gzip_file:
    run: ../../tools/basic/gzip.cwl
    label: Gzip output
    scatter: file
    in:
      file: fasterq_dum/output
    out: [ output ]
  fastqc:
    run: ../../tools/fastqc/fastqc.cwl
    label: fastqc
    in:
      fastq: gzip_file/output
      threads: threads
    out: [out_html, out_zip]
