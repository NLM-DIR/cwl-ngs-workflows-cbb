#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: bedtools-bamtobed
doc: The bedtools utilities are a swiss-army knife of tools for a wide-range of genomics analysis tasks

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: bedtools-docker.yml
  - $import: bedtools-bioconda.yml

inputs:
  stdout:
    type: string
    doc: Stdout from program
  bedpe:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -bedpe
    doc: |
      Write BAM alignments in BEDPE format. Only one alignment from paired-end reads will be reported.
      Specifically, it each mate is aligned to the same chromosome, the BAM alignment reported will
      be the one where the BAM insert size is greater than zero. When the mate alignments are
      interchromosomal, the lexicographically lower chromosome will be reported first. Lastly,
      when an end is unmapped, the chromosome and strand will be set to “.” and the start and
      end coordinates will be set to -1. By default, this is disabled and the output will be
      reported in BED format.
  mate1:
    type: boolean?
    inputBinding:
      position: 2
      prefix: -mate1
    doc: |
      When writing BEDPE (-bedpe) format, always report mate one as the first BEDPE “block”.
  bed12:
    type: boolean?
    inputBinding:
      position: 3
      prefix: -bed12
    doc: |
      Write “blocked” BED (a.k.a. BED12) format. This will convert “spliced” BAM alignments
      (denoted by the “N” CIGAR operation) to BED12. Forces -split.
  split:
    type: boolean?
    inputBinding:
      position: 4
      prefix: -split
    doc: |
      Report each portion of a “split” BAM (i.e., having an “N” CIGAR operation) alignment as
      a distinct BED intervals.
  i:
    type: File
    inputBinding:
      position: 5
      prefix: -i
    doc: Input BAM format


outputs:
  out_stdout:
    type: File
    outputBinding:
      glob: $(inputs.stdout)

stdout: $(inputs.stdout)

baseCommand: [bedtools, bamtobed]
