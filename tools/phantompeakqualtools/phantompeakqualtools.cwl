#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Phantompeakqualtools
doc: This package computes informative enrichment and quality measures for ChIP-seq/DNase-seq/FAIRE-seq/MNase-seq data

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: $(inputs.p)
    ramMin: 2048

hints:
  - $import: phantompeakqualtools-docker.yml
  - $import: phantompeakqualtools-bioconda.yml

inputs:
  p:
    type: int?
    inputBinding:
      position: 1
      prefix: -p=
      separate: false
    doc: |
      Threads.
  npeak:
    type: int?
    inputBinding:
      position: 1
      prefix: -npeak=
      separate: false
    doc: |
      threshold on number of peaks to call
  speak:
    type: int?
    inputBinding:
      position: 1
      prefix: -speak=
      separate: false
    doc: |
      user-defined cross-correlation peak strandshift
  c:
    type: File?
    inputBinding:
      position: 1
      prefix: -c=
      separate: false
    doc: |
      full path and name (or URL) of tagAlign/BAM file (can be gzipped) (FILE EXTENSION MUST BE tagAlign.gz, tagAlign, bam or bam.gz)
  i:
    type: File?
    inputBinding:
      position: 1
      prefix: -i=
      separate: false
    doc: |
      Cotrol: full path and name (or URL) of tagAlign/BAM file (can be gzipped) (FILE EXTENSION MUST BE tagAlign.gz, tagAlign, bam or bam.gz)
  filtchr:
    type: string?
    inputBinding:
      position: 2
      prefix: -filtchr=
      separate: false
  savp:
    type: string?
    inputBinding:
      position: 2
      prefix: -savp=
      separate: false
  savr:
    type: string?
    inputBinding:
      position: 2
      prefix: -savr=
      separate: false
  savn:
    type: string?
    inputBinding:
      position: 2
      prefix: -savn=
      separate: false
  out:
    type: string
    inputBinding:
      position: 3
      prefix: -out=
      separate: false

outputs:
  output_savp:
    type: File?
    outputBinding:
      glob: $(inputs.savp)
  output_savr:
    type: File?
    outputBinding:
      glob: $(inputs.savr)
  output_savn:
    type: File?
    outputBinding:
      glob: $(inputs.savn)
  output_out:
    type: File
    outputBinding:
      glob: $(inputs.out)

baseCommand: ["run_spp.R", "-rf"]
