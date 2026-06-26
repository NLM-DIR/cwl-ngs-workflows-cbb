class: Workflow
cwlVersion: v1.0
doc: >-
  This workflow execute peak caller and QC from ChIP-Seq and ATAC-Seq for
  single-end samples
label: ATAC-Seq peak caller workflow for single-end samples

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  input_bam:
    type: File
    secondaryFiles:
      - .bai
  macs_callpeaks_g:
    type: string
  macs_callpeaks_q:
    type: float

outputs:
  macs_callpeak_q_value_narrowPeak:
    outputSource: macs_callpeak_q_value/narrowPeak
    type: File
  macs_cutoff_inflection:
    outputSource: macs_cutoff/out_inflection
    type: File
  macs_cutoff_pdf:
    outputSource: macs_cutoff/out_pdf
    type: File

steps:
  macs_callpeak:
    run: ../../tools/macs/macs3-callpeak.cwl
    label: MACS2-callpeak
    in:
      B: { default: true}
      cutoff-analysis: { default: true}
      extsize: { default: 73}
      f: { default: "BAM"}
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      nomodel: { default: true}
      q: macs_callpeaks_q
      shift: { default: -37}
      t: input_bam
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "macs";}
    out: [cutoff_analysis]
  macs_cutoff:
    run: ../../tools/R/macs-cutoff.cwl
    label: MACS2_cutoff
    in:
      peak_cutoff_file: macs_callpeak/cutoff_analysis
      out_pdf_name:
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + ".pdf";}
      out_inflection_name:
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + "_inflection.txt";}
    out: [ out_inflection, out_pdf ]
  macs_callpeak_q_value:
    run: ../../tools/macs/macs3-callpeak.cwl
    label: MACS2-callpeak
    in:
      B: { default: true}
      call-summits: { default: true}
      cutoff-analysis: { default: true}
      extsize: { default: 73}
      f: { default: "BAM"}
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      nomodel: { default: true}
      q_file: macs_cutoff/out_inflection
      shift: { default: -37}
      t: input_bam
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_macs";}
    out:
      [ lambda, pileup, narrowPeak, xls, bed ]
