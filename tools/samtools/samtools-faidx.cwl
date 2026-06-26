#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Samtools-faidx
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.input)

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  o:
    type: string
    inputBinding:
      position: 1
      prefix: -o
    doc: |
      Write FASTA to file.
  n:
    type: int?
    inputBinding:
      position: 1
      prefix: -n
    doc: |
      Length of FASTA sequence line. [60]
  c:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -c
    doc: |
      Continue after trying to retrieve missing region.
  r:
    type: File?
    inputBinding:
      position: 1
      prefix: -r
    doc: |
      File of regions.  Format is chr:from-to. One per line.
  i:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -i
    doc: |
      Reverse complement sequences.
  f:
    type: File?
    inputBinding:
      position: 1
      prefix: -f
    doc: |
      File and index in FASTQ format.
  mark_strand:
    type: string?
    inputBinding:
      position: 1
      prefix: --mark-strand
    doc: |
      Add strand indicator to sequence name
          TYPE = rc   for /rc on negative strand (default)
                 no   for no strand indicator
                 sign for (+) / (-)
                 custom,<pos>,<neg> for custom indicator
  input:
    type: File
    inputBinding:
      position: 2

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.o)

baseCommand: [samtools, faidx]
