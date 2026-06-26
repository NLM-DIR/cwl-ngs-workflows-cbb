cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

label: "Bisulfite Methylation Caller for paired-end"
doc: "This workflow execute Bisulfite Methylation base don Bismark"

inputs:
  genome: Directory
  threads: int
  maxins: int?
  read_1: File
  read_2: File
  buffer_size: string?
  ignore: int?

outputs:
  deduplicated_bam:
    outputSource: deduplication/bam
    type: File
  deduplicated_report:
    outputSource: deduplication/report
    type: File
  methylation_CHG:
    outputSource: methylation_caller/CHG
    type: File?
  methylation_CHH:
    outputSource: methylation_caller/CHH
    type: File?
  methylation_CpG:
    outputSource: methylation_caller/CpG
    type: File?
  methylation_report:
    outputSource: methylation_caller/report
    type: File?

steps:
  alignment:
    run: ../../tools/bismark/bismark.cwl
    in:
      genome: genome
      maxins: maxins
      p: threads
      read_1: read_1
      read_2: read_2
      basename:
        valueFrom: |
          ${
              var nameroot = inputs.read_1.nameroot;
              if (nameroot.endsWith(".fastq")){
                 nameroot = nameroot.replace(".fastq", "")
              }
              if (nameroot.endsWith("_1") || nameroot.endsWith("_2")){
                 nameroot = nameroot.slice(0, -2);
              }
              return nameroot;
           }
    out: [bam, report]
  deduplication:
    run: ../../tools/bismark/deduplicate_bismark.cwl
    in:
      paired: { default: True}
      input: alignment/bam
      outfile:
        valueFrom: ${ return inputs.input.nameroot;}
    out: [bam, report]
  methylation_caller:
    run: ../../tools/bismark/bismark_methylation_extractor.cwl
    in:
      buffer_size: buffer_size
      comprehensive: { default: True}
      parallel: threads
      paired: { default: True}
      input: deduplication/bam
      ignore: ignore
    out: [CHG, CHH, CpG, report]
