class: Workflow
cwlVersion: v1.2

id: starrseq_alignment
label: STARR-seq alignment workflow
doc: >-
  Aligns one or more STARR-seq FASTQ run pairs to a reference genome using
  BWA-MEM, coordinate-sorts each BAM, optionally merges multiple runs into a
  single BAM, and removes duplicates with Picard MarkDuplicates.
  Read groups (@RG) are auto-generated from the FASTQ filenames so Picard
  can correctly scope optical duplicate detection per run while treating all
  runs as the same library (same SM and LB tags).

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  runs:
    type:
      type: array
      items:
        type: array
        items: File
    doc: >-
      Array of FASTQ run pairs. Each element is [R1, R2] for paired-end or
      [R1] for single-end. Single run: [[R1, R2]]. Multiple runs:
      [[R1a, R2a], [R1b, R2b], ...].
  sample_name:
    type: string
    doc: >-
      Biological sample name. Used as SM and LB read-group tags (so Picard
      treats all runs as one library) and as the prefix for the merged BAM.
  genome_index:
    type: Directory
    doc: Directory containing the BWA genome index files.
  genome_prefix:
    type: string
    doc: Prefix of the BWA index files inside genome_index.
  threads:
    type: int?
    doc: Number of threads for BWA and samtools steps.
  bwa_k:
    type: int?
  bwa_c:
    type: int?
  bwa_T:
    type: int?
  readsquality:
    type: int?
    default: 30
    doc: Minimum MAPQ applied inside the Picard dedup sub-workflow.

outputs:
  dedup_bam:
    type: File
    secondaryFiles: [ .bai ]
    outputSource: remove_duplicates/dedup_bam
    doc: >-
      Coordinate-sorted, deduplicated, indexed BAM. Primary input for
      BasicSTARRseq (both cDNA/sample and input-DNA/control runs).
  bam_flagstat_out:
    type: File[]
    outputSource: alignment/bam_flagstat_out
    doc: Per-run flagstat immediately after BWA alignment.
  bam_stats_out:
    type: File[]
    outputSource: alignment/bam_stats_out
    doc: Per-run samtools stats immediately after BWA alignment.
  dedup_metrics:
    type: File
    outputSource: remove_duplicates/dedup_metrics
    doc: Picard MarkDuplicates metrics (duplication rates).
  dedup_flagstat:
    type: File
    outputSource: remove_duplicates/dedup_flagstat
    doc: Flagstat after duplicate marking and MAPQ filtering.

steps:

  # -------------------------------------------------------------------
  # Generate one @RG string per run from the FASTQ filename.
  # Picard requires:
  #   ID  - unique per run (derived from filename, e.g. SRR12539162)
  #   SM  - sample name   (shared across runs → same biological sample)
  #   LB  - library name  (shared across runs → Picard marks cross-run
  #                         duplicates from the same library preparation)
  #   PL  - platform
  #   PU  - platform unit (run-specific; used for optical-dup detection)
  # -------------------------------------------------------------------
  generate_rg:
    run:
      class: ExpressionTool
      requirements:
        InlineJavascriptRequirement: {}
      inputs:
        runs:
          type:
            type: array
            items:
              type: array
              items: File
        sample_name: string
      outputs:
        bwa_R: string[]
      expression: |
        ${
          var rgs = inputs.runs.map(function(pair) {
            var nm = pair[0].nameroot;
            nm = nm.replace(/_R?[12](_\d+)?$/, '');
            return "@RG\\tID:" + nm +
                   "\\tSM:" + inputs.sample_name +
                   "\\tLB:" + inputs.sample_name +
                   "\\tPL:ILLUMINA" +
                   "\\tPU:" + nm;
          });
          return { "bwa_R": rgs };
        }
    in:
      runs: runs
      sample_name: sample_name
    out: [bwa_R]

  # -------------------------------------------------------------------
  # Align each run in parallel (scatter over runs + bwa_R in lockstep)
  # -------------------------------------------------------------------
  alignment:
    run: ../Alignments/bwa-alignment.cwl
    label: BWA-MEM alignment
    scatter: [reads, bwa_R]
    scatterMethod: dotproduct
    in:
      reads: runs
      bwa_R: generate_rg/bwa_R
      genome_index: genome_index
      genome_prefix: genome_prefix
      threads: threads
      bwa_k: bwa_k
      bwa_c: bwa_c
      bwa_T: bwa_T
    out: [bam_out, bam_flagstat_out, bam_stats_out]

  # -------------------------------------------------------------------
  # Coordinate-sort each aligned BAM (scattered)
  # -------------------------------------------------------------------
  sort_bam:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    scatter: in_bam
    in:
      in_bam: alignment/bam_out
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam"; }
      threads: threads
    out: [out_sam]

  # -------------------------------------------------------------------
  # Merge sorted BAMs — only runs when there is more than one run.
  # When skipped (single run), output is null (File?).
  # -------------------------------------------------------------------
  merge_bams:
    run: ../../tools/samtools/samtools-merge.cwl
    label: Samtools-merge
    when: $(inputs.in_bam.length > 1)
    in:
      threads: threads
      in_bam: sort_bam/out_sam
      out_bam:
        source: sample_name
        valueFrom: $(self + "_merged.bam")
    out: [out_sam]

  # -------------------------------------------------------------------
  # Pick the BAM to deduplicate:
  #   multiple runs → merged BAM
  #   single run    → the one sorted BAM from sort_bam
  # -------------------------------------------------------------------
  pick_bam:
    run:
      class: ExpressionTool
      requirements:
        InlineJavascriptRequirement: {}
      inputs:
        merged: File?
        sorted: File[]
      outputs:
        bam: File
      expression: |
        ${
          return { "bam": inputs.merged ? inputs.merged : inputs.sorted[0] };
        }
    in:
      merged: merge_bams/out_sam
      sorted: sort_bam/out_sam
    out: [bam]

  # -------------------------------------------------------------------
  # Remove duplicates with Picard MarkDuplicates
  # -------------------------------------------------------------------
  remove_duplicates:
    run: ../Duplication/remove-duplication-picard.cwl
    label: Picard MarkDuplicates
    in:
      bam: pick_bam/bam
      threads:
        source: threads
        valueFrom: |
          ${ return self !== null ? self : 1; }
      readsquality:
        source: readsquality
        valueFrom: |
          ${ return self !== null ? self : 30; }
      assay_type: { default: "starrseq" }
    out: [dedup_bam, dedup_metrics, dedup_flagstat, dedup_bed]
