class: CommandLineTool
cwlVersion: v1.2

label: gatk-GenomicsDBImport
doc: GATK suite

hints:
  - $import: gatk-docker.yml
  - $import: gatk-bioconda.yml

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  threads:
    type: int?
    inputBinding:
      position: 3
      prefix: --reader-threads
  genomicsdb_workspace_path:
    type: string
    inputBinding:
      position: 3
      prefix: --genomicsdb-workspace-path
  L:
    type: string
    inputBinding:
      position: 4
      prefix: -L
  V:
    type: File[]
    inputBinding:
      shellQuote: False
      position: 5
      valueFrom: |
        ${
           var listing = "";
           for (var i = 0; i < inputs.V.length; i++) {
              listing += " -V " + inputs.V[i].path;
           }
           return listing;
         }
  java_options:
    type: string?
    inputBinding:
      position: 1
      prefix: --java-options
  gatk_command:
    type: string
    default: "GenomicsDBImport"
    inputBinding:
      position: 2
      shellQuote: False

outputs:
  output:
    type: Directory
    outputBinding:
      glob: $(inputs.genomicsdb_workspace_path)

baseCommand: [gatk]
