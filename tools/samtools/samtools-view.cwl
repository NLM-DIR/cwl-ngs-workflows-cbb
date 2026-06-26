#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-view
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: $(inputs.threads)

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  S:
    type: boolean
    default: false
    inputBinding:
      position: 2
      prefix: -S
    doc: |
      input format is auto-detected
  isbam:
    type: boolean
    default: false
    inputBinding:
      position: 2
      prefix: -b
    doc: |
      output in BAM format
  readswithoutbits:
    type: string?
    inputBinding:
      position: 1
      prefix: -F
    doc: |
      only include reads with none of the bits set in INT set in FLAG [0]
  collapsecigar:
    type: boolean?
    default: false
    inputBinding:
      position: 1
      prefix: -B
    doc: |
      collapse the backward CIGAR operation
  readsingroup:
    type: string?
    inputBinding:
      position: 1
      prefix: -r
    doc: |
      only include reads in read group STR [null]
  bedoverlap:
    type: File?
    inputBinding:
      position: 1
      prefix: -L
    doc: |
      only include reads overlapping this BED FILE [null]
  uncompressed:
    type: boolean?
    default: false
    inputBinding:
      position: 1
      prefix: -u
    doc: |
      uncompressed BAM output (implies -b)
  readtagtostrip:
    type: string[]?
    inputBinding:
      position: 1
    doc: |
      read tag to strip (repeatable) [null]
  input:
    type: File
    inputBinding:
      position: 4
    doc: |
      Input bam file.
  readsquality:
    type: int?
    inputBinding:
      position: 1
      prefix: -q
    doc: |
      only include reads with mapping quality >= INT [0]
  readswithbits:
    type: string?
    inputBinding:
      position: 1
      prefix: -f
    doc: |
      only include reads with all bits set in INT set in FLAG [0]
  cigar:
    type: int?
    inputBinding:
      position: 1
      prefix: -m
    doc: |
      only include reads with number of CIGAR operations
      consuming query sequence >= INT [0]
  iscram:
    type: boolean?
    default: false
    inputBinding:
      position: 2
      prefix: -C
    doc: |
      output in CRAM format
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: -@
    doc: |
      number of BAM compression threads [0]
  fastcompression:
    type: boolean?
    default: false
    inputBinding:
      position: 1
      prefix: '-1'
    doc: |
      use fast BAM compression (implies -b)
  samheader:
    type: boolean?
    default: false
    inputBinding:
      position: 1
      prefix: -h
    doc: |
      include header in SAM output
  count:
    type: boolean?
    default: false
    inputBinding:
      position: 1
      prefix: -c
    doc: |
      print only the count of matching records
  randomseed:
    type: float?
    inputBinding:
      position: 1
      prefix: -s
    doc: |
      integer part sets seed of random number generator [0];
      rest sets fraction of templates to subsample [no subsampling]
  referencefasta:
    type: File?
    inputBinding:
      position: 1
      prefix: -T
    doc: |
      reference sequence FASTA FILE [null]
  region:
    type: string?
    inputBinding:
      position: 5
    doc: |
      [region ...]
  readsingroupfile:
    type: File?
    inputBinding:
      position: 1
      prefix: -R
    doc: |
      only include reads with read group listed in FILE [null]
  readsinlibrary:
    type: string?
    inputBinding:
      position: 1
      prefix: -l
    doc: |
      only include reads in library STR [null]
  output_name:
    type: string
    inputBinding:
      position: 2
      prefix: -o
  s:
    type: float?
    inputBinding:
      position: 1
      prefix: -s
  U:
    type: File?
    inputBinding:
      position: 1
      prefix: -U
  H:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -H

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.output_name)

baseCommand: [samtools, view]
