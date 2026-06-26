class: CommandLineTool
cwlVersion: v1.2

label: gatk-SelectVariants
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  LoadListingRequirement:
    loadListing: no_listing
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

inputs:
  V:
    type: File?
    secondaryFiles: [.idx]
    inputBinding:
      position: 4
      prefix: -V
  db:
    type: Directory?
    inputBinding:
      position: 5
      prefix: -V
      valueFrom: ${ return "gendb://" + self.path;}
  R:
    type: File?
    secondaryFiles: [.fai, ^.dict]
    inputBinding:
      position: 6
      prefix: -R
  O:
    type: string
    inputBinding:
      position: 7
      prefix: -O
  selectType:
    type: string?
    inputBinding:
      position: 8
      prefix: --select-type-to-include
  exclude-filtered:
    type: boolean?
    inputBinding:
      position: 9
      prefix: --exclude-filtered
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "SelectVariants"
    inputBinding:
      position: 2
      shellQuote: False
  gatk_subcommand:
    type: string
    default: "-OVI"
    inputBinding:
      position: 3
      shellQuote: False

outputs:
  output:
    type: File
    secondaryFiles: [.idx]
    outputBinding:
      glob: $(inputs.O)

baseCommand: [gatk]
