class: CommandLineTool
cwlVersion: v1.2

label: gatk-GatherVcfs
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  I:
    type: File[]
    secondaryFiles: [ .tbi ]
    inputBinding:
      shellQuote: False
      position: 3
      valueFrom: |
        ${
           var listing = "";
           for (var i = 0; i < inputs.I.length; i++) {
              listing += " -I " + inputs.I[i].path;
           }
           return listing;
         }
  O:
    type: string
    inputBinding:
      position: 4
      prefix: -O
      valueFrom: |
        ${
            return (self.endsWith(".vcf.gz")) ? self : self + ".vcf.gz";
        }
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "GatherVcfs"
    inputBinding:
      position: 2
      shellQuote: False

outputs:
  output:
    type: File
    secondaryFiles: [ .tbi ]
    outputBinding:
      glob: $(inputs.O)

baseCommand: [gatk]
