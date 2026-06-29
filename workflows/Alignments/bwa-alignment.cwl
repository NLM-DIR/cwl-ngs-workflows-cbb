class: Workflow
cwlVersion: v1.2

id: bwa_alignment
doc: This workflow aligns the fastq files using bwa
label: bwa alignment workflow

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}

inputs:
  reads: File[]
  genome_index: Directory
  genome_prefix: string
  threads: int?
  bwa_k: int?
  bwa_c: int?
  bwa_T: int?
  bwa_R: string?

outputs:
  bam_out:
    outputSource: bam_index/out_sam
    type: File
  bam_flagstat_out:
    outputSource: samtools_flagstat/out_stdout
    type: File
  bam_stats_out:
    outputSource: samtools_stats/out_stdout
    type: File

steps:
  bwa_mem:
    run: ../../tools/bwa/bwa-mem.cwl
    label: bwa-mem
    in:
      M: {default: true}
      Y: {default: true}
      index: genome_index
      reads: reads
      prefix: genome_prefix
      t: threads
      k: bwa_k
      c: bwa_c
      T: bwa_T
      R: bwa_R
    out: [out_stdout]
  samtools_view:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: bwa_mem/out_stdout
      isbam: {default: true}
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".bam";}'
      threads: threads
    out: [output]
  samtools_sort:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: samtools_view/output
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam"; }
      threads: threads
    out: [out_sam]
  bam_index:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: samtools_sort/out_sam
    out: [out_sam]
  samtools_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: bam_index/out_sam
      stdout:
        valueFrom: '${ return inputs.in_bam.nameroot + ".flagstat";}'
    out: [out_stdout]
  samtools_stats:
    run: ../../tools/samtools/samtools-stats.cwl
    label: Samtools-stats
    in:
      in_bam: bam_index/out_sam
      stdout:
        valueFrom: '${ return inputs.in_bam.nameroot + ".stats";}'
    out: [out_stdout]
