class: CommandLineTool
cwlVersion: v1.2

label: gatk-GenotypeGVCFs
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  ShellCommandRequirement: { }
  InlineJavascriptRequirement: { }

inputs:
  R:
    type: File
    secondaryFiles:
      - ".fai"
      - "^.dict"
    inputBinding:
      position: 3
      prefix: -R
  V:
    type: Directory
    inputBinding:
      position: 4
      prefix: -V
      valueFrom: |
        ${
            return "gendb://" + self.path;
        }
  O:
    type: string
    inputBinding:
      position: 5
      prefix: -O
      valueFrom: |
        ${
            return (self.endsWith(".vcf.gz")) ? self : self + ".vcf.gz";
        }
  include_non_variant_sites:
    type: boolean?
    inputBinding:
      position: 6
      prefix: --include-non-variant-sites
  ploidy:
    type: int?
    inputBinding:
      position: 7
      prefix: --sample-ploidy
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "GenotypeGVCFs"
    inputBinding:
      position: 2
      shellQuote: False

outputs:
  output:
    type: File
    secondaryFiles: [ .tbi ]
    outputBinding:
      glob: $(inputs.O)

baseCommand: [ gatk ]
