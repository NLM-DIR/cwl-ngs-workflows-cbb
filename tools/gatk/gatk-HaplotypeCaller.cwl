class: CommandLineTool
cwlVersion: v1.2

label: gatk-HaplotypeCaller
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  InlineJavascriptRequirement: { }
  ResourceRequirement:
    coresMin: $(inputs.threads)
    ramMin: 8000
    ramMax: 64000
  EnvVarRequirement:
    envDef:
      OMP_NUM_THREADS: "$(inputs.threads.toString())"

inputs:
  I:
    type: File
    secondaryFiles: [ .bai, .sbi ]
    inputBinding:
      position: 3
      prefix: -I
  R:
    type: File
    secondaryFiles: [ .fai, ^.dict ]
    inputBinding:
      position: 4
      prefix: -R
  O:
    type: string
    inputBinding:
      position: 5
      prefix: -O
      valueFrom: |
        ${
            return (self.endsWith(".vcf.gz")) ? self : self + ".vcf.gz";
        }
  threads:
    type: int
    inputBinding:
      position: 6
      prefix: --native-pair-hmm-threads
  intervals:
    type: string?
    inputBinding:
      position: 7
      prefix: --intervals
  ERC:
    type: string?
    inputBinding:
      position: 8
      prefix: -ERC
  create_output_variant_index:
    type: string?
    inputBinding:
      position: 9
      prefix: --create-output-variant-index
  ploidy:
    type: int?
    inputBinding:
      position: 10
      prefix: --ploidy
  annotations:
    type: string[]?
    inputBinding:
      position: 11
      shellQuote: False
      valueFrom: |
        ${
          return self.flatMap(function(x) { return ["-A", x]; });
        }
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "HaplotypeCaller"
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
