#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: HOMER-makeTagDirectory
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
      position: 2
    doc: |
      Input file: BED, SAM, bowtie, etc.
  tags_directory_name:
    type: string
    inputBinding:
      position: 1
    doc: |
      Output directory name with tags files
  fragLength:
    type: string?
    inputBinding:
      position: 3
      prefix: -fragLength
    doc: |
      Set estimated fragment length or use PE length - given: use read lengths
  format:
    type: string?
    inputBinding:
      position: 4
      prefix: -format
    doc: |
      Input file format: BED, SAM, bowtie, etc.
  flip:
    type: boolean?
    inputBinding:
      position: 5
      prefix: -flip
    doc: |
      flip strand of each read, i.e. might want to use with some RNA-seq
  totalReads:
    type: string?
    inputBinding:
      position: 6
      prefix: -totalReads
    doc: |
      <#|all|default> (set the effective total number of reads - all includes multimappers)
  force5th:
    type: string?
    inputBinding:
      position: 7
      prefix: -force5th
    doc: |
      (5th column of BED file contains # of reads mapping to position)
  d:
    type: Directory[]?
    inputBinding:
      position: 8
      prefix: -d
    doc: |
      <tag directory> [tag directory 2] ... (add Tag directory to new tag directory)
  t:
    type: File[]?
    inputBinding:
      position: 9
      prefix: -t
    doc: |
      <tag file> [tag file 2] ... (add tag file i.e. *.tags.tsv to new tag directory)
  single:
    type: boolean?
    inputBinding:
      position: 10
      prefix: -single
    doc: |
      (Create a single tags.tsv file for all "chromosomes" - i.e. if >100 chromosomes)
  update:
    type: boolean?
    inputBinding:
      position: 11
      prefix: -update
    doc: |
      (Use current tag directory for QC/processing, do not parse new alignment files)
  tbp:
    type: int?
    inputBinding:
      position: 12
      prefix: -tbp
    doc: |
      <#> (Maximum tags per bp, default: no maximum)
  precision:
    type: int?
    inputBinding:
      position: 13
      prefix: -precision
    doc: |
      <1|2|3> (number of decimal places to use for tag totals, default: 1)
  minlen:
    type: int?
    inputBinding:
      position: 14
      prefix: -minlen
    doc: |
      <#> and -maxlen <#> (Filter reads with lengths outside this range)
  genome:
    type: File
    inputBinding:
      position: 15
      prefix: -genome
    doc: |
      <path-to-FASTA file or directory of FASTA files>
  checkGC:
    type: boolean?
    inputBinding:
      position: 16
      prefix: -checkGC
    doc: |
      check Sequence bias, requires "-genome"

outputs:
  tags_directory:
    type: Directory
    outputBinding:
      glob: $(inputs.tags_directory_name)

baseCommand: [makeTagDirectory]
