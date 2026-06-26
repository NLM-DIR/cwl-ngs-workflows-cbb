class: Workflow
cwlVersion: v1.2

id: starrseq_alignment
label: STARR-seq alignment workflow
doc: >-
  Aligns STARR-seq FASTQ files (input DNA or cDNA library) to a reference
  genome using BWA-MEM, coordinate-sorts the BAM, and removes duplicates
  with Picard MarkDuplicates. Produces a deduplicated indexed BAM ready
  for BasicSTARRseq peak calling.

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}

inputs:
  reads:
    type: File[]
    doc: Input FASTQ file(s). Single FASTQ for SE, two for PE.
  genome_index:
    type: Directory
    doc: Directory containing the BWA genome index files.
  genome_prefix:
    type: string
    doc: Prefix of the BWA index files inside genome_index.
  threads:
    type: int?
    doc: Number of threads for BWA and samtools.
  bwa_k:
    type: int?
  bwa_c:
    type: int?
  bwa_T:
    type: int?
  bwa_R:
    type: string?
    doc: Read group string passed to BWA (-R).
  readsquality:
    type: int?
    default: 30
    doc: Minimum MAPQ for samtools filtering inside Picard dedup workflow.

outputs:
  # --- deduplicated BAM: primary output, feeds BasicSTARRseq ---
  dedup_bam:
    type: File
    secondaryFiles: [ .bai ]
    outputSource: remove_duplicates/dedup_bam
    doc: >-
      Coordinate-sorted, deduplicated, indexed BAM. Primary input for
      BasicSTARRseq peak calling (both sample/cDNA and control/input runs).

  # --- QC outputs ---
  bam_flagstat_out:
    type: File
    outputSource: alignment/bam_flagstat_out
    doc: Flagstat of the raw BAM immediately after BWA alignment.
  bam_stats_out:
    type: File
    outputSource: alignment/bam_stats_out
    doc: Samtools stats of the raw BAM immediately after BWA alignment.
  dedup_metrics:
    type: File
    outputSource: remove_duplicates/dedup_metrics
    doc: Picard MarkDuplicates metrics file (duplication rates).
  dedup_flagstat:
    type: File
    outputSource: remove_duplicates/dedup_flagstat
    doc: Flagstat of the BAM after duplicate marking and filtering.

steps:
  alignment:
    run: ../Alignments/bwa-alignment.cwl
    label: BWA-MEM alignment
    in:
      reads: reads
      genome_index: genome_index
      genome_prefix: genome_prefix
      threads: threads
      bwa_k: bwa_k
      bwa_c: bwa_c
      bwa_T: bwa_T
      bwa_R: bwa_R
    out: [bam_out, bam_flagstat_out, bam_stats_out]

  sort_bam:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: alignment/bam_out
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam"; }
      threads: threads
    out: [out_sam]

  remove_duplicates:
    run: ../Duplication/remove-duplication-picard.cwl
    label: Picard MarkDuplicates
    in:
      bam: sort_bam/out_sam
      threads: threads
      readsquality: readsquality
      assay_type: { default: "starrseq" }
    out: [dedup_bam, dedup_metrics, dedup_flagstat, dedup_bed]
