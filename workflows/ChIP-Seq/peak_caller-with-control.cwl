class: Workflow
cwlVersion: v1.2
doc: >-
  This workflow execute peak caller and QC from ChIP-Seq.
  For TF 
    1. Do not use broad, call-summits, broad-cutoff. 
    2. nomodel = True
  For Histones (H3K27me3, H3K9me3, H3K36me3): 
    1. Use broad, call-summits, broad-cutoff == 0.1.
    2. nomodel = False
  For other histone marks: 
    1. Do not use broad, broad-cutoff.
    2. nomodel = False
    3. call-summits = True
label: ChIP-Seq

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
  bam_flagstat:
    type: File
  control_bam:
    type: File?
    secondaryFiles:
      - .bai
  macs_callpeaks_g:
    type: string
  macs_callpeaks_q:
    type: float
  nomodel:
    type: boolean?
  extsize:
    type: int?
  cutoff-analysis:
    type: boolean?
    default: true
  broad:
    type: boolean?
  broad-cutoff:
    type: float?
  call-summits:
    type: boolean?

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
  broadPeak:
    outputSource: macs_callpeak_q_value/broadPeak
    type: File?
  gappedPeak:
    outputSource: macs_callpeak_q_value/gappedPeak
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
    label: MACS3-callpeak
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
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      t: input_bam
      c: control_bam
      q: macs_callpeaks_q
      B: { default: true}
      nomodel:
        valueFrom: |
          ${
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            if (!is_paired) {
              return true;
            }
            // Paired-end: respect user input
            return inputs.nomodel;
          }
      extsize:
        valueFrom: |
          ${
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            if (!is_paired) {
              return 147;  // or empirical value
            }
            return inputs.extsize;
          }
      cutoff-analysis: cutoff-analysis
      call-summits: call-summits
      broad: broad
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_macs" ;}
    out: [cutoff_analysis, narrowPeak, broadPeak]
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
    label: MACS3-callpeak
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
      g: macs_callpeaks_g
      n:
        valueFrom: ${ return inputs.t.nameroot;}
      t: input_bam
      c: control_bam
      macs_callpeaks_q: macs_callpeaks_q
      q:
        valueFrom: |
          ${
              return inputs.q_file ? null: inputs.macs_callpeaks_q;
           }
      q_file: macs_cutoff/out_inflection
      call-summits: call-summits
      broad: broad
      B: { default: true }
      nomodel:
        source: nomodel
        valueFrom: |
          ${
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            // Single-end: force nomodel
            if (!is_paired) {
              return true;
            }
            // Paired-end: respect user input
            return inputs.nomodel;
          }
      extsize:
        source: extsize
        valueFrom: |
          ${
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            if (!is_paired) {
              return 147;  // or empirical value
            }
            return inputs.extsize;
          }
      outdir_name:
        valueFrom: ${ return inputs.t.nameroot + "_macs";}
    out:
      [ lambda, pileup, narrowPeak, xls, bed, broadPeak, gappedPeak]
