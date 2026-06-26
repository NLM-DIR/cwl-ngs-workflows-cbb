cwlVersion: v1.0
class: CommandLineTool

label: Bismark methylation extractor
doc: Bismark is a program to map bisulfite

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: |
      ${
                return inputs.parallel ? inputs.parallel : 1
        }
    ramMin: |
      ${
          return inputs.buffer_size ? parseInt(inputs.buffer_size.replace('G','')) : 2000
      }

hints:
  - $import: bismark-docker.yml
  - $import: bismark-bioconda.yml

inputs:
  single:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --single-end
  paired:
    type: boolean?
    inputBinding:
      position: 2
      prefix: --paired-end
  no_overlap:
    type: boolean?
    inputBinding:
      position: 3
      prefix: --no_overlap
  include_overlap:
    type: boolean?
    inputBinding:
      position: 4
      prefix: --include_overlap
  ignore:
    type: int?
    inputBinding:
      position: 5
      prefix: --ignore
  ignore_r2:
    type: int?
    inputBinding:
      position: 6
      prefix: --ignore_r2
  ignore_3prime:
    type: int?
    inputBinding:
      position: 7
      prefix: --ignore_3prime
  ignore_3prime_r2:
    type: int?
    inputBinding:
      position: 7
      prefix: --ignore_3prime_r2
  comprehensive:
    type: boolean?
    inputBinding:
      position: 8
      prefix: --comprehensive
  merge_non_CpG:
    type: boolean?
    inputBinding:
      position: 9
      prefix: --merge_non_CpG
  parallel:
    type: int?
    inputBinding:
      position: 10
      prefix: --parallel
  bedGraph:
    type: boolean?
    inputBinding:
      position: 11
      prefix: --bedGraph
  buffer_size:
    type: string?
    inputBinding:
      position: 12
      prefix: --buffer_size
  cytosine_report:
    type: boolean?
    inputBinding:
      position: 13
      prefix: --cytosine_report
  genome_folder:
    type: Directory?
    inputBinding:
      position: 14
      prefix: --genome_folder
  input:
    type: File
    inputBinding:
      position: 100

outputs:
  CHG:
    type: File?
    outputBinding:
      glob: CHG_context_$(inputs.input.nameroot).txt.gz
  CHG_OB:
    type: File?
    outputBinding:
      glob: CHG_OB_$(inputs.input.nameroot).txt.gz
  CHG_OT:
    type: File?
    outputBinding:
      glob: CHG_OT_$(inputs.input.nameroot).txt.gz
  CHH:
    type: File?
    outputBinding:
      glob: CHH_context_$(inputs.input.nameroot).txt.gz
  CHH_OB:
    type: File?
    outputBinding:
      glob: CHH_OB_$(inputs.input.nameroot).txt.gz
  CHH_OT:
    type: File?
    outputBinding:
      glob: CHH_OT_$(inputs.input.nameroot).txt.gz
  CpG:
    type: File?
    outputBinding:
      glob: CpG_context_$(inputs.input.nameroot).txt.gz
  CpG_OB:
    type: File?
    outputBinding:
      glob: CpG_OB_$(inputs.input.nameroot).txt.gz
  CpG_OT:
    type: File?
    outputBinding:
      glob: CpG_OT_$(inputs.input.nameroot).txt.gz
  bedGraph_out:
    type: File?
    outputBinding:
      glob: $(inputs.input.nameroot).bedGraph.gz
  bismark_cov:
    type: File?
    outputBinding:
      glob: $(inputs.input.nameroot).bismark.cov.gz
  report:
    type: File?
    outputBinding:
      glob: $(inputs.input.nameroot)_splitting_report.txt


baseCommand: ["bismark_methylation_extractor", "--gzip"]
