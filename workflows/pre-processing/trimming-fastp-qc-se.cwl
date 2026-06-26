class: Workflow
cwlVersion: v1.0

id: trimming_quality_control
label: trimming_quality_control

requirements:
  SubworkflowFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  in1: File
  cut_mean_quality: int?
  average_qual: int?
  length_required: int?
  max_len1: int?
  thread: int
  trim_poly_x: boolean?
  poly_x_min_len: int?
  trim_poly_g: boolean?
  poly_g_min_len: int?
  adapter_sequence: string?
  adapter_sequence_r2: string?
  adapter_fasta: File?
  cut_front: boolean?
  cut_tail: boolean?

outputs:
  fastqc_html:
    outputSource: fastqc/out_html
    type: File[]
  fastqc_zip:
    outputSource: fastqc/out_zip
    type: File[]
  fastq1:
    outputSource: trimming/r1
    type: File
  report:
    outputSource: trimming/r
    type: File?

steps:
  trimming:
    label: FastP
    run: ../../tools/fastp/fastp.cwl
    in:
      in1: in1
      out1:
        valueFrom: ${ return inputs.in1.basename; }
      cut_mean_quality: cut_mean_quality
      average_qual: average_qual
      length_required: length_required
      max_len1: max_len1
      trim_poly_g: trim_poly_g
      poly_g_min_len: poly_g_min_len
      trim_poly_x: trim_poly_x
      poly_x_min_len: poly_x_min_len
      adapter_sequence: adapter_sequence
      adapter_sequence_r2: adapter_sequence_r2
      adapter_fasta: adapter_fasta
      cut_front: cut_front
      cut_tail: cut_tail
      thread: thread
      json:
        valueFrom: |
          ${
            var nameroot = inputs.in1.nameroot;
            if (nameroot.endsWith(".fastq")){
               nameroot = nameroot.replace(".fastq", "")
            }
            if (nameroot.endsWith("_1") || nameroot.endsWith("_2")){
               nameroot = nameroot.slice(0, -2);
            }
            return nameroot + ".json";
          }
    out: [r1, r2, r]
  fastqc:
    run: ../../tools/fastqc/fastqc.cwl
    label: fastqc
    in:
      fastq:
        source:
          - trimming/r1
        valueFrom: |
          ${
            return self ? [self] : [];
          }
      threads: thread
    out: [out_html, out_zip]
