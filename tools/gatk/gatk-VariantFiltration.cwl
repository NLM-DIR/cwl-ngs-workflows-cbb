class: CommandLineTool
cwlVersion: v1.2

label: gatk-VariantFiltration
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  ShellCommandRequirement: { }
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
    type: File
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
  filters:
    type: { "type": "array", "items": { "type": "array", "items": "string" } }
    inputBinding:
      position: 7
      shellQuote: false
      valueFrom: |
        ${
            var argument = "";
            for (var j = 0; j < inputs.filters.length; j++) {
              argument += '--filter-name "' +  inputs.filters[j][0] + '" --filter-expression "' + inputs.filters[j][1] + '" ';
            }
            return argument;
         }
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "VariantFiltration"
    inputBinding:
      position: 2
      shellQuote: False
  gatk_subcommand:
    type: string
    default: "-OVI"
    inputBinding:
      position: 3
      shellQuote: False
  missing_values_evaluate_as_failing:
    type: string?
    inputBinding:
      position: 4
      prefix: --missing-values-evaluate-as-failing

outputs:
  output:
    type: File
    secondaryFiles: [ .tbi ]
    outputBinding:
      glob: $(inputs.O)

baseCommand: [ gatk ]
