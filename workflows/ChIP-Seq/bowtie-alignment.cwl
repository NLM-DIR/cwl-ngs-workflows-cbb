class: Workflow
cwlVersion: v1.2

id: bowtie_alignment
doc: This workflow aligns the fastq files using bowtie
label: bowtie alignment workflow

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}

inputs:
  all: boolean?
  k: int?
  very_sensitive: boolean?
  reads: File[]
  bowtie_index:
    type: File
    secondaryFiles:
      - .1.bt2
      - .2.bt2
      - .3.bt2
      - .4.bt2
      - .rev.1.bt2
      - .rev.2.bt2

  threads: int?

outputs:
  bam_out:
    outputSource: samtools_view/output
    type: File
  bam_flagstat_out:
    outputSource: samtools_flagstat/out_stdout
    type: File
  bam_stats_out:
    outputSource: samtools_stats/out_stdout
    type: File

steps:
  alignment:
    run: ../../tools/bowtie/bowtie2.cwl
    in:
      p: threads
      q: { default: true }
      all: all
      k: k
      S: { default: true }
      x: bowtie_index
      no_discordant: { default: true }
      no_mixed: { default: true }
      very_sensitive: very_sensitive
      no_unal: { default: true }
      omit_sec_seq: { default: true }
      xeq: { default: true }
      reorder: { default: true }
      fastq1:
        source: reads
        valueFrom: $(self[0])
      fastq2:
        source: reads
        valueFrom: $(self[1])
    out: [output]
  samtools_view:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: alignment/output
      isbam: {default: true}
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".bam";}'
      threads: threads
    out: [output]
  samtools_flagstat:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: samtools_view/output
      stdout:
        valueFrom: '${ return inputs.in_bam.nameroot + ".flagstat";}'
    out: [out_stdout]
  samtools_stats:
    run: ../../tools/samtools/samtools-stats.cwl
    label: Samtools-stats
    in:
      in_bam: samtools_view/output
      stdout:
        valueFrom: '${ return inputs.in_bam.nameroot + ".stats";}'
    out: [out_stdout]
