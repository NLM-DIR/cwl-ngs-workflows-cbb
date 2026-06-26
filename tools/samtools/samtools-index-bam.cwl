cwlVersion: v1.2
class: CommandLineTool

label: Samtools-index-bam
doc: Samtools is a suite of programs for interacting with high-throughput sequencing data

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.bam)

hints:
  - $import: samtools-docker.yml
  - $import: samtools-bioconda.yml

inputs:
  bam:
    type: File
    inputBinding:
      position: 1

outputs:
  indexed_bam:
    type: File
    secondaryFiles: [.bai]
    outputBinding:
      glob: $(inputs.bam.basename)

baseCommand: [samtools, index, -b]
