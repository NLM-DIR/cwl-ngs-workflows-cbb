cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

label: "Bisulfite Methylation Caller for single-end"
doc: "This workflow execute Bisulfite Methylation base don Bismark"

inputs:
  genome: Directory
  threads: int
  read: File
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
      p: threads
      single: read
      basename:
        valueFrom: |
          ${
              var nameroot = inputs.single.nameroot;
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
      single: { default: True}
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
      single: { default: True}
      input: deduplication/bam
      ignore: ignore
    out: [CHG, CHH, CpG, report]
