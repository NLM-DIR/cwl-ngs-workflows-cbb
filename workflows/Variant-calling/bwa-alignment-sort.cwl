class: Workflow
cwlVersion: v1.2

id: bwa_alignment_sort
doc: This workflow aligns the fastq files using bwa, sort and index the BAM file
label: bwa alignment workflow

requirements:
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}

inputs:
  reads: File[]
  genome_index: Directory
  genome_prefix: string
  threads: int
  R: string

outputs:
  sorted_indexed_bam:
    outputSource: sort_and_index/sorted_indexed_bam
    type: File
    secondaryFiles: [ .bai ]
  bam_flagstat_out:
    outputSource: bam_flagstat/out_stdout
    type: File
  bam_stats_out:
    outputSource: bam_stats/out_stdout
    type: File

steps:
  alignment:
    run: ../../tools/bwa/bwa-mem.cwl
    label: bwa-mem
    in:
      reads: reads
      index: genome_index
      prefix: genome_prefix
      t: threads
      K: { default: 100000000}
      Y: { default: true}
      R: R
    out: [out_stdout]
  sam_to_bam:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: alignment/out_stdout
      isbam: {default: true}
      output_name:
        valueFrom: ${ return inputs.input.nameroot + ".bam";}
      threads: threads
    out: [output]
  bam_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: sam_to_bam/output
      stdout:
        valueFrom: ${ return inputs.in_bam.nameroot + ".flagstat";}
    out: [out_stdout]
  bam_stats:
    run: ../../tools/samtools/samtools-stats.cwl
    label: Samtools-stats
    in:
      in_bam: sam_to_bam/output
      stdout:
        valueFrom: ${ return inputs.in_bam.nameroot + ".stats";}
    out: [out_stdout]
  sort_and_index:
    run: samtools-sort_index.cwl
    in:
      bam: sam_to_bam/output
      threads: threads
    out: [sorted_indexed_bam]

