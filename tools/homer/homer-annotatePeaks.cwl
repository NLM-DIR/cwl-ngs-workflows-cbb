#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: HOMER-annotatePeaks
doc: Software for motif discovery and next generation sequencing analysis

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

hints:
  - $import: homer-docker.yml
  - $import: homer-bioconda.yml

inputs:
  input:
    type: File
    inputBinding:
      position: 1
    doc: |
      Peak/BED file
  o:
    type: string
  genome:
    type: File
    inputBinding:
      position: 2
    doc: |
      Genome version: hg19, hg38
  annStats:
    type: string?
    inputBinding:
      position: 3
      prefix: -annStats
  d:
    type: Directory?
    inputBinding:
      position: 4
      prefix: -d
  fpkm:
    type: boolean?
    inputBinding:
      position: 5
      prefix: -fpkm
  gtf:
    type: File?
    inputBinding:
      position: 6
      prefix: -gtf
    doc: |
      GTF definition file
  gff:
    type: File?
    inputBinding:
      position: 6
      prefix: -gff
    doc: |
      GFF definition file
  gff3:
    type: File?
    inputBinding:
      position: 6
      prefix: -gff3
    doc: |
      GFF3 definition file

outputs:
  output:
    type: stdout
  annStats_out:
    type: File?
    outputBinding:
      glob: $(inputs.annStats)

stdout: $(inputs.o)

baseCommand: [annotatePeaks.pl]
