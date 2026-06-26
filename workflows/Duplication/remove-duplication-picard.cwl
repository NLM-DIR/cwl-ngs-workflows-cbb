class: Workflow
cwlVersion: v1.2

id: remove-duplication-picard
doc: Unified ChIP-seq / ATAC-seq preprocessing that mark duplicates with Picard, filter reads with samtools, and emit BAM + BED.
label: Remove duplicated reads with Picard

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  bam: File
  threads: int
  assay_type:
    type:
      type: enum
      symbols: [chipseq, atacseq, starrseq]
    default: chipseq
  readsquality:
    type: int
    default: 30

outputs:
  dedup_bam:
    outputSource: dedup_index_bam/out_sam
    type: File
    secondaryFiles: [ .bai ]
  dedup_metrics:
    outputSource: mark_duplicates_picard/metrics_out
    type: File
  dedup_flagstat:
    outputSource: flagstat_markdup_bam/out_stdout
    type: File
  dedup_bed:
    outputSource: bamtobed/out_stdout
    type: File

steps:
  mark_duplicates_picard:
    run: ../../tools/picard/picard-markduplicates.cwl
    label: Picard-MarkDuplicates
    doc: Mark duplicates (do not remove) for both ChIP-seq and ATAC-seq; downstream filtering controls whether duplicates are excluded.
    in:
      input: bam
      output:
        valueFrom: ${ return inputs.input.nameroot.replace("_sorted", "_markdup.bam");}
      metrics:
        valueFrom: ${ return inputs.input.nameroot.replace("_sorted", "_markdup_metrics.txt");}
      validation: { default: "LENIENT"}
      sorted: { default: "true"}
      remove_duplicates: { default: "false"}
    out: [ output_bam, metrics_out ]
  index_markdup_bam:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: mark_duplicates_picard/output_bam
    out: [ out_sam ]
  flagstat_markdup_bam:
    run: ../../tools/samtools/samtools-flagstat.cwl
    label: Samtools-flagstat
    in:
      in_bam: index_markdup_bam/out_sam
      stdout:
        valueFrom: ${ return inputs.in_bam.nameroot + "_flagstat.txt";}
    out: [ out_stdout ]
  dedup_filter_bam:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      flagstat:
        source: flagstat_markdup_bam/out_stdout
        loadContents: true
      assay_type: assay_type
      input: index_markdup_bam/out_sam
      isbam: { default: true }
      output_name:
        valueFrom: ${ return inputs.input.nameroot.replace("_markdup", "_dedup.bam");}
      threads: threads
      readsquality:
        valueFrom: |
          ${
            // ENCODE-style default for ATAC-seq is typically MAPQ>=20.
            // For ChIP-seq, keep the existing conservative default (30),
            // unless the user overrides via the workflow input.
            if (inputs.assay_type === "atacseq") {
              return Math.min(inputs.readsquality ?? 30, 20) === 20 ? 20 : inputs.readsquality;
            }
            return inputs.readsquality ?? 30;
          }
      readswithbits:
        valueFrom: |
          ${
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            if (is_paired) {
              // -f 3 : paired + properly paired
              return "3";
            }
            return null;
          }
      readswithoutbits:
        valueFrom: |
          ${
            // Always remove PCR/optical duplicates (0x400).
            // Also remove secondary (0x100) and supplementary (0x800) alignments.
            // ChIP-seq historically also removed unmapped (0x4) + mate-unmapped (0x8) reads.
            // For ATAC-seq, avoid filtering on mate-unmapped here; rely on proper-pair (-f 3)
            // when paired, and keep SE behavior minimal.
            var text = inputs.flagstat.contents;
            var match = text.match(/^(\d+)\s+\+\s+\d+\s+paired in sequencing/m);
            var is_paired = parseInt(match[1], 10) > 0;
            if (is_paired) {
              if (inputs.assay_type === "atacseq") {
                // 0x400 + 0x100 + 0x800 = 1024 + 256 + 2048 = 3328
                return "3328";
              }
              // ChIP-seq PE: 0x4 + 0x8 + 0x100 + 0x400 + 0x800 = 4 + 8 + 256 + 1024 + 2048 = 3340
              return "3340";
            }
            // SE: do not filter on paired/proper-pair bits
            if (inputs.assay_type === "starrseq") {
              // 0x4 unmapped + 0x100 secondary + 0x400 PCR-dup + 0x800 supplementary = 3332
              return "3332";
            }
            return "1024";
          }
    out: [ output ]
  dedup_sort_bam:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: dedup_filter_bam/output
      out_bam:
        valueFrom: ${ return inputs.in_bam.nameroot + "_sorted.bam";}
      threads: threads
    out: [ out_sam ]
  dedup_index_bam:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: dedup_sort_bam/out_sam
    out: [ out_sam ]
  bamtobed:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    in:
      i: dedup_index_bam/out_sam
      stdout:
        valueFrom: ${ return inputs.i.nameroot + ".bed";}
    out: [ out_stdout ]