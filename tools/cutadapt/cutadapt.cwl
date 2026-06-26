cwlVersion: v1.2
class: CommandLineTool

label: cutadapt
doc: Cutadapt trimming tool

requirements:
  InlineJavascriptRequirement: { }
  ResourceRequirement:
    coresMin: $(inputs.cores)

hints:
  - $import: cutadapt-docker.yml
  - $import: cutadapt-bioconda.yml

inputs:
  cores:
    type: int?
    default: 1
    inputBinding:
      position: 1
      prefix: --cores
  quality_cutoff:
    type: string?
    inputBinding:
      position: 2
      prefix: --quality-cutoff
  length:
    type: int?
    inputBinding:
      position: 3
      prefix: --length
  poly_a:
    type: boolean?
    inputBinding:
      position: 4
      prefix: --poly-a
  trim_n:
    type: boolean?
    inputBinding:
      position: 5
      prefix: --trim-n
  minimum_length:
    type: int?
    inputBinding:
      position: 6
      prefix: --minimum-length
  maximum_length:
    type: int?
    inputBinding:
      position: 7
      prefix: --maximum-length
  report:
    type: string?
    inputBinding:
      position: 8
      prefix: --report
  json:
    type: string?
    inputBinding:
      position: 9
      prefix: --json
  output:
    type: string
    inputBinding:
      position: 10
      prefix: --output
  fasta:
    type: boolean?
    inputBinding:
      position: 11
      prefix: --fasta
  a:
    type: File?
    inputBinding:
      position: 12
      prefix: -a
    doc: Sequence of an adapter ligated to the 3'
  g:
    type: File?
    inputBinding:
      position: 13
      prefix: -g
    doc: Sequence of an adapter ligated to the 5' end
  b:
    type: File?
    inputBinding:
      position: 14
      prefix: -b
    doc: Sequence of an adapter that may be ligated to the 5' or 3' end
  error_rate:
    type: float?
    inputBinding:
      position: 15
      prefix: --error-rate
  A:
    type: File?
    inputBinding:
      position: 16
      prefix: -A
    doc: 3' adapter to be removed from R2
  G:
    type: File?
    inputBinding:
      position: 17
      prefix: -G
    doc: 5' adapter to be removed from R2
  B:
    type: File?
    inputBinding:
      position: 18
      prefix: -b
    doc: 5'/3 adapter to be removed from R2
  U:
    type: int?
    inputBinding:
      position: 19
      prefix: -U
    doc: Remove LENGTH bases from R2
  L:
    type: int?
    inputBinding:
      position: 20
      prefix: -L
    doc: Shorten R2 to LENGTH. Default same as for R1
  paired_output:
    type: string?
    inputBinding:
      position: 21
      prefix: --paired-output
  pair_adapters:
    type: boolean?
    inputBinding:
      position: 22
      prefix: --pair-adapters
  overlap:
    type: int?
    inputBinding:
      position: 23
      prefix: --overlap
    doc: Require MINLENGTH overlap between read and adapter for an adapter to be found.
  nextseq_trim:
    type: boolean?
    inputBinding:
      position: 24
      prefix: --nextseq-trim

outputs:
  r1:
    type: File
    outputBinding:
      glob: $(inputs.output)
  r2:
    type: File?
    outputBinding:
      glob: $(inputs.paired_output)
  r:
    type: File?
    outputBinding:
      glob: $(inputs.json)

baseCommand: [ cutadapt ]
