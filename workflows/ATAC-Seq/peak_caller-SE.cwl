class: Workflow
cwlVersion: v1.0
doc: >-
  This workflow execute peak caller and QC from ChIP-Seq and ATAC-Seq for
  single-end samples
label: ATAC-Seq peak caller workflow for single-end samples
$namespaces:
  s: 'http://schema.org/'
inputs:
  - id: genome_fasta
    type: File
  - id: genome_gtf
    type: File
  - id: homer_genome
    type: string
  - id: input_bam
    type: File
    secondaryFiles:
      - .bai
  - id: input_bed
    type: File
  - id: macs_callpeaks_g
    type: string
  - id: macs_callpeaks_q
    type: float
outputs:
  - id: ChIPQC_report
    outputSource:
      - ChIPQC/report
    type: Directory
  - id: homer_annotate_peaks_annStats
    outputSource:
      - homer_annotate_peaks/annStats_out
    type: File?
  - id: homer_annotate_peaks_output
    outputSource:
      - homer_annotate_peaks/output
    type: File
  - id: macs_callpeak_q_value_narrowPeak
    outputSource:
      - macs_callpeak_q_value/narrowPeak
    type: File
  - id: macs_callpeak_q_value_xls
    outputSource:
      - macs_callpeak_q_value/xls
    type: File
  - id: macs_callpeak_q_value_bed
    outputSource:
      - macs_callpeak_q_value/bed
    type: File
  - id: macs_cutoff_inflection
    outputSource:
      - macs_cutoff/out_inflection
    type: File
  - id: macs_cutoff_pdf
    outputSource:
      - macs_cutoff/out_pdf
    type: File
  - id: phantompeakqualtools_output_out
    outputSource:
      - phantompeakqualtools/output_out
    type: File
  - id: phantompeakqualtools_output_savp
    outputSource:
      - phantompeakqualtools/output_savp
    type: File
  - id: readQC_plots
    outputSource:
      - readQC/plots
    type: 'File[]'
steps:
  - id: ChIPQC
    in:
      - id: input
        source: input_bam
    out:
      - id: report
    run: ../../tools/R/chipqc.cwl
    label: ChIPQC
  - id: homer_annotate_peaks
    in:
      - id: annStats
        valueFrom: '${ return inputs.macs_out_dir.basename + ''_annStats.txt'';}'
      - id: d
        source: homer_tags/tags_directory
      - id: fpkm
        default: true
      - id: genome
        source: homer_genome
      - id: gtf
        source: genome_gtf
      - id: input
        valueFrom: '${ return inputs.macs_out_dir.basename + ''.narrowPeak'';}'
      - id: macs_out_dir
        source: macs_callpeak/outdir
      - id: o
        valueFrom: '${ return inputs.macs_out_dir.basename + ''_annotation.txt'';}'
    out:
      - id: annStats_out
      - id: output
    run: ../../tools/homer/homer-annotatePeaks.cwl
    label: HOMER-annotatePeaks
  - id: homer_tags
    in:
      - id: checkGC
        default: true
      - id: format
        default: bed
      - id: genome
        source: genome_fasta
      - id: input
        source: input_bed
    out:
      - id: tags_directory
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    label: HOMER-makeTagDirectory
  - id: macs_callpeak
    in:
      - id: B
        default: true
      - id: cutoff-analysis
        default: true
      - id: extsize
        default: 73
      - id: f
        default: BAM
      - id: g
        source: macs_callpeaks_g
      - id: 'n'
        valueFrom: '${ return inputs.t.nameroot;}'
      - id: nomodel
        default: true
      - id: q
        source: macs_callpeaks_q
      - id: shift
        default: -37
      - id: t
        source: input_bam
    out:
      - id: cutoff_analysis
    run: ../../tools/macs/macs2-callpeak.cwl
    label: MACS2-callpeak
  - id: macs_callpeak_q_value
    in:
      - id: B
        default: true
      - id: call-summits
        default: true
      - id: cutoff-analysis
        default: true
      - id: extsize
        default: 73
      - id: f
        default: BAM
      - id: g
        source: macs_callpeaks_g
      - id: 'n'
        valueFrom: '${ return inputs.t.nameroot;}'
      - id: nomodel
        default: true
      - id: q_file
        source: macs_cutoff/out_inflection
      - id: shift
        default: -37
      - id: t
        source: input_bam
    out:
      - id: [lambda, pileup, narrowPeak, xls, bed]
    run: ../../tools/macs/macs2-callpeak.cwl
    label: MACS2-callpeak
  - id: macs_cutoff
    in:
      - id: peak_cutoff_file
        source: cutoff_analysis
      - id: out_pdf_name
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + ".pdf";}
      - id: out_inflection_name
        valueFrom: ${ return inputs.peak_cutoff_file.nameroot + "_inflection.txt";}
    out:
      - id: out_inflection
      - id: out_pdf
    run: ../../tools/R/macs-cutoff.cwl
    label: MACS2_cutoff
  - id: phantompeakqualtools
    in:
      - id: c
        source: input_bam
      - id: out
        valueFrom: '${ return inputs.c.nameroot + "_metrics.txt";}'
      - id: savp
        valueFrom: '${ return inputs.c.nameroot + "_cross_correlation.pdf";}'
    out:
      - id: output_out
      - id: output_savn
      - id: output_savp
      - id: output_savr
    run: ../../tools/phantompeakqualtools/phantompeakqualtools.cwl
    label: Phantompeakqualtools
  - id: readQC
    in:
      - id: tags_directory
        source: homer_tags/tags_directory
    out:
      - id: plots
    run: ../../tools/R/readQC.cwl
    label: readQC
requirements: []
