cwlVersion: v1.0
class: CommandLineTool

label: Bismark
doc: Bismark is a program to map bisulfite

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: |
      ${
                return inputs.p ? inputs.p : 1
        }

hints:
  - $import: bismark-docker.yml
  - $import: bismark-bioconda.yml

inputs:
  p:
    type: int?
    inputBinding:
      position: 1
      prefix: -p
  genome:
    type: Directory
    inputBinding:
      position: 2
      prefix: --genome
  bowtie2:
    type: boolean?
    inputBinding:
      position: 3
      prefix: --bowtie2
  hisat2:
    type: boolean?
    inputBinding:
      position: 3
      prefix: --hisat2
  basename:
    type: string
    inputBinding:
      position: 3
      prefix: --basename
  minins:
    type: int?
    inputBinding:
      position: 1
      prefix: --minins
  maxins:
    type: int?
    inputBinding:
      position: 1
      prefix: --maxins
  read_1:
    type: File?
    inputBinding:
      position: 99
      prefix: "-1"
  read_2:
    type: File?
    inputBinding:
      position: 100
      prefix: "-2"
  single:
    type: File?
    inputBinding:
      position: 100

outputs:
  bam:
    type: File
    outputBinding:
      glob: |
        ${
            if (inputs.read_1){
              return inputs.basename + "_pe.bam";
            } 
            return inputs.basename + ".bam";
        }
  report:
    type: File
    outputBinding:
      glob: $(inputs.basename)_*_report.txt

baseCommand: ["bismark"]
