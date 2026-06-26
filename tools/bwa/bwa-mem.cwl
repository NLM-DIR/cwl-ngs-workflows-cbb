class: CommandLineTool
cwlVersion: v1.2

label: bwa-mem
doc: >-
  BWA is a software package for mapping DNA sequences against a large reference
  genome

hints:
  - $import: bwa-docker.yml
  - $import: bwa-bioconda.yml

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: $(inputs.t)
    ramMin: 10240

inputs:
  M:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-M'
  A:
    type: int?
    inputBinding:
      position: 1
      prefix: '-A'
      separate: false
  B:
    type: int?
    inputBinding:
      position: 1
      prefix: '-B'
      separate: false
  E:
    type: int?
    inputBinding:
      position: 1
      prefix: '-E'
      separate: false
  L:
    type: int?
    inputBinding:
      position: 1
      prefix: '-L'
      separate: false
  T:
    type: int?
    inputBinding:
      position: 1
      prefix: '-T'
  K:
    type: int?
    inputBinding:
      position: 1
      prefix: '-K'
  Y:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-Y'
  R:
    type: string?
    inputBinding:
      position: 1
      prefix: '-R'
  a:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-a'
  S:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-S'
  P:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-P'
  five:
    type: boolean?
    inputBinding:
      position: 1
      prefix: '-5'
  index:
    type: Directory
  reads:
    type: File[]
    inputBinding:
      position: 5
  prefix:
    type: string
    inputBinding:
      position: 4
      valueFrom: |
        ${
          return inputs.index.path + "/" + self;
        }
  t:
    type: int?
    inputBinding:
      position: 1
      prefix: '-t'
  k:
    type: int?
    inputBinding:
      position: 1
      prefix: -k
    doc: minimum seed length [19]
  c:
    type: int?
    inputBinding:
      position: 1
      prefix: -c
    doc: skip seeds with more than INT occurrences [500]


outputs:
  out_stdout:
    type: File
    outputBinding:
      glob: |
        ${
          var nameroot = inputs.reads[0].nameroot;
          if (nameroot.endsWith(".fastq")){
            nameroot = nameroot.replace(".fastq", "");
          }else if (nameroot.endsWith(".fq")){
            nameroot = nameroot.replace(".fq", "");
          }
          if (nameroot.endsWith("_1") || nameroot.endsWith("_2")){
            nameroot = nameroot.slice(0, -2);
          }else if (nameroot.includes("_R1_")){
            nameroot = nameroot.substring(0, nameroot.indexOf("_R1_"))
          }else if (nameroot.includes("_R2_")){
            nameroot = nameroot.substring(0, nameroot.indexOf("_R2_"))
          }
          return nameroot + '.sam';
        }

stdout: |
  ${
    var nameroot = inputs.reads[0].nameroot;
    if (nameroot.endsWith(".fastq")){
      nameroot = nameroot.replace(".fastq", "");
    }else if (nameroot.endsWith(".fq")){
      nameroot = nameroot.replace(".fq", "");
    }
    if (nameroot.endsWith("_1") || nameroot.endsWith("_2")){
      nameroot = nameroot.slice(0, -2);
    }else if (nameroot.includes("_R1_")){
      nameroot = nameroot.substring(0, nameroot.indexOf("_R1_"))
    }else if (nameroot.includes("_R2_")){
      nameroot = nameroot.substring(0, nameroot.indexOf("_R2_"))
    }
    return nameroot + '.sam';
  }

baseCommand: [bwa, mem]
