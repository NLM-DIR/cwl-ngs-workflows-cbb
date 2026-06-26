class: Workflow
cwlVersion: v1.0

id: trimming_quality_control
label: trimming_quality_control

requirements:
  SubworkflowFeatureRequirement: { }
  InlineJavascriptRequirement: { }
  ScatterFeatureRequirement: { }
  StepInputExpressionRequirement: { }
  MultipleInputFeatureRequirement: { }

inputs:
  in1: File
  in2: File
  cut_mean_quality: int?
  average_qual: int?
  length_required: int?
  max_len1: int?
  max_len2: int?
  thread: int
  cut_front: boolean?
  cut_tail: boolean?
  trim_front1: int?
  trim_front2: int?
  adapter_sequence: string?
  adapter_sequence_r2: string?
  adapter_fasta: File?
  detect_adapter_for_pe: boolean?
  cut_window_size: int?
  trim_poly_x: boolean?
  poly_x_min_len: int?
  trim_poly_g: boolean?
  poly_g_min_len: int?

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
  fastq2:
    outputSource: trimming/r2
    type: File?
  report:
    outputSource: trimming/r
    type: File?

steps:
  trimming:
    label: FastP
    run: ../../tools/fastp/fastp.cwl
    in:
      in1: in1
      in2: in2
      out1:
        valueFrom: ${ return inputs.in1.basename; }
      out2:
        valueFrom: ${ return inputs.in2.basename; }
      detect_adapter_for_pe: detect_adapter_for_pe
      trim_poly_g: trim_poly_g
      poly_g_min_len: poly_g_min_len
      trim_poly_x: trim_poly_x
      poly_x_min_len: poly_x_min_len
      cut_mean_quality: cut_mean_quality
      cut_front: cut_front
      cut_tail: cut_tail
      cut_window_size: cut_window_size
      average_qual: average_qual
      length_required: length_required
      max_len1: max_len1
      max_len2: max_len2
      trim_front1: trim_front1
      trim_front2: trim_front2
      adapter_sequence: adapter_sequence
      adapter_sequence_r2: adapter_sequence_r2
      adapter_fasta: adapter_fasta
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
    out: [ r1, r2, r ]
  fastqc:
    run: ../../tools/fastqc/fastqc.cwl
    label: fastqc
    in:
      fastq:
        source:
          - trimming/r1
          - trimming/r2
        valueFrom: |
          ${
            return self.filter(function(f){ return f !== null; });
          }
      threads: thread
    out: [ out_html, out_zip ]
