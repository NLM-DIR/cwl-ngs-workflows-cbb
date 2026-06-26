class: CommandLineTool
cwlVersion: v1.2

label: gatk-SelectVariants
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  InlineJavascriptRequirement: { }
  ResourceRequirement:
    ramMin: 1024

inputs:
  V:
    type: File
    secondaryFiles: [ .tbi ]
    inputBinding:
      position: 4
      prefix: -V
  R:
    type: File?
    secondaryFiles: [ .fai, ^.dict ]
    inputBinding:
      position: 5
      prefix: -R
  O:
    type: string
    inputBinding:
      position: 6
      prefix: -O
      valueFrom: |
        ${
            return (self.endsWith(".vcf.gz")) ? self : self + ".vcf.gz";
        }
  selectType:
    type: string?
    inputBinding:
      position: 7
      prefix: --select-type-to-include
  exclude-filtered:
    type: boolean?
    inputBinding:
      position: 8
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
  annotations:
    type: string[]?
    inputBinding:
      position: 11
      shellQuote: False
      valueFrom: |
        ${
          return self.flatMap(function(x) { return ["-A", x]; });
        }

outputs:
  output:
    type: File
    secondaryFiles: [ .tbi ]
    outputBinding:
      glob: $(inputs.O)

baseCommand: [ gatk ]
