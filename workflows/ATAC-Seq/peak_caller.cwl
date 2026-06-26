class: Workflow
cwlVersion: v1.2
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
  bam:
    type: File
    secondaryFiles:
      - .bai
  bam_flagstat:
    type: File
  macs_callpeaks_g:
    type: string
  macs_callpeaks_q:
    type: float
  cutoff-analysis:
    type: boolean?
    default: true

outputs:
  lambda:
    outputSource: macs_callpeak_q_value/lambda
    type: File
  pileup:
    outputSource: macs_callpeak_q_value/pileup
    type: File
  narrowPeak:
    outputSource: macs_callpeak_q_value/narrowPeak
    type: File?
  xls:
    outputSource: macs_callpeak_q_value/xls
    type: File
  bed:
    outputSource: macs_callpeak_q_value/bed
    type: File?
  macs_cutoff_inflection:
    outputSource: macs_cutoff/out_inflection
    type: File?
  macs_cutoff_pdf:
    outputSource: macs_cutoff/out_pdf
    type: File?

steps:
  macs_callpeak:
    when: $(inputs["cutoff-analysis"] == true)
    run: ../../tools/macs/macs3-callpeak.cwl
    label: MACS2-callpeak
    in:
      flagstat:
        source: bam_flagstat
        loadContents: true
      B: { default: true}
      cutoff-analysis: cutoff-analysis
      f:
        valueFrom: |
          ${
              var text = inputs.flagstat.contents;
              var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
              var is_paired = parseInt(match[1], 10) > 0;
              if (is_paired) {
                return "BAMPE";
              }
              return "BAM";
            }
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      nomodel: { default: true}
      q: macs_callpeaks_q
      shift: { default: -100}
      extsize: { default: 200}
      t: bam
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "macs";}
    out: [cutoff_analysis]
  macs_cutoff:
    when: $(inputs.peak_cutoff_file != null)
    run: ../../tools/R/macs-cutoff.cwl
    label: MACS2_cutoff
    in:
      peak_cutoff_file: macs_callpeak/cutoff_analysis
      out_pdf_name:
        valueFrom: |
          ${ 
             return inputs.peak_cutoff_file ? inputs.peak_cutoff_file.nameroot + ".pdf" : null;
           }
      out_inflection_name:
        valueFrom: |
          ${ 
              return inputs.peak_cutoff_file ? inputs.peak_cutoff_file.nameroot + "_inflection.txt" : null;
           }
    out: [ out_inflection, out_pdf ]
  macs_callpeak_q_value:
    run: ../../tools/macs/macs3-callpeak.cwl
    label: MACS2-callpeak
    in:
      flagstat:
        source: bam_flagstat
        loadContents: true
      f:
        valueFrom: |
          ${
              var text = inputs.flagstat.contents;
              var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
              var is_paired = parseInt(match[1], 10) > 0;
              if (is_paired) {
                return "BAMPE";
              }
              return "BAM";
            }
      B: { default: true}
      call-summits: { default: true}
      cutoff-analysis: { default: true}
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      nomodel: { default: true}
      macs_callpeaks_q: macs_callpeaks_q
      q:
        valueFrom: |
          ${
              return inputs.q_file ? null: inputs.macs_callpeaks_q;
           }
      q_file: macs_cutoff/out_inflection
      shift: { default: -100 }
      extsize: { default: 200 }
      t: bam
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_macs";}
    out:
      [ lambda, pileup, narrowPeak, xls, bed ]
