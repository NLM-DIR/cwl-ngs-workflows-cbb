class: CommandLineTool
cwlVersion: v1.2

label: Samtools-stats
doc: >-
  Samtools is a suite of programs for interacting with high-throughput
  sequencing data

requirements:
  - class: InlineJavascriptRequirement

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  - id: in_bam
    type: File
    inputBinding:
      position: 1
  - id: stdout
    type: string
outputs:
  - id: out_stdout
    type: File
    outputBinding:
      glob: $(inputs.stdout)

stdout: $(inputs.stdout)

baseCommand:
  - samtools
  - stats
