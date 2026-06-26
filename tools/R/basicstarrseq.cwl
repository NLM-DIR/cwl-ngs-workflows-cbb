#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: BasicSTARRseq
doc: >-
  Peak calling on STARR-seq data using the BasicSTARRseq Bioconductor package.
  Identifies enhancers by comparing cDNA (sample) vs input DNA (control) BAM
  files. Applies BH-adjusted p-value and enrichment filters to reproduce the
  Tan et al. (2023) thresholds (adj P < 0.01, enrichment > 1.3).

hints:
  - $import: basicstarrseq-docker.yml
  - $import: basicstarrseq-bioconda.yml

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: basicstarrseq.R
        entry: |
          args <- commandArgs(trailingOnly = TRUE)

          sample_bam     <- args[1]
          control_bam    <- args[2]
          sample_name    <- args[3]
          paired_end     <- as.logical(args[4])
          min_quantile   <- as.numeric(args[5])
          peak_width     <- as.integer(args[6])
          max_padj       <- as.numeric(args[7])
          min_enrichment <- as.numeric(args[8])
          deduplicate    <- as.logical(args[9])
          model          <- as.integer(args[10])
          genome_fasta      <- if (!is.na(args[11]) && nchar(args[11]) > 0) args[11] else NULL
          reference_genome  <- if (!is.na(args[12]) && nchar(args[12]) > 0) args[12] else "unknown"

          suppressPackageStartupMessages({
            library(BasicSTARRseq)
            library(GenomicRanges)
          })

          # ---------------------------------------------------------------
          # Provenance: document intentional deviation from package defaults
          # ---------------------------------------------------------------
          message("=== BasicSTARRseq provenance ===")
          message("  Package default : maxPval = 0.001 (raw p-value filter inside getPeaks)")
          message("  Workflow override: maxPval = 1    (no internal raw-pval filtering)")
          message("  Reason: Tan et al. (2023) report BH-adjusted P < 0.01.")
          message("          BasicSTARRseq returns only raw p-values.")
          message("          BH correction is therefore applied externally after getPeaks().")
          message("  Post-hoc filters applied here:")
          message("    padj       < ", max_padj,       "  (BH-adjusted, paper threshold)")
          message("    enrichment >= ", min_enrichment, "  (paper threshold)")
          message("================================")

          message(">>> Loading STARR-seq data")
          message("    sample BAM : ", sample_bam)
          message("    control BAM: ", control_bam)
          message("    paired-end : ", paired_end)

          data <- STARRseqData(
            sample    = sample_bam,
            control   = control_bam,
            pairedEnd = paired_end
          )

          message(">>> Chromosome sanity check")
          message("    seqlevels: ", paste(seqlevels(sample(data)), collapse = ", "))

          # Pass maxPval=1 to collect all peaks; BH adjustment is applied below
          # so we do not pre-filter on raw p-value and lose peaks that would
          # pass the adjusted threshold.
          message(">>> Calling peaks (maxPval=1, BH adjustment applied after)")
          message("    minQuantile  = ", min_quantile)
          message("    peakWidth    = ", peak_width)
          message("    deduplicate  = ", deduplicate)
          message("    model        = ", model)

          peaks <- getPeaks(
            data,
            minQuantile = min_quantile,
            peakWidth   = peak_width,
            maxPval     = 1,
            deduplicate = deduplicate,
            model       = model
          )

          message(">>> Raw peaks before any filtering: ", length(peaks))

          # BH adjustment on raw p-values across all candidate peaks
          peaks$padj <- p.adjust(peaks$pVal, method = "BH")

          # Apply paper thresholds: adj P < max_padj AND enrichment >= min_enrichment
          peaks <- peaks[
            !is.na(peaks$padj)       & peaks$padj       <  max_padj       &
            !is.na(peaks$enrichment) & peaks$enrichment >= min_enrichment
          ]

          message(">>> Enhancers after adj P < ", max_padj,
                  " and enrichment >= ", min_enrichment, ": ", length(peaks))

          if (length(peaks) == 0) {
            message("WARNING: no enhancers passed filters. Check BAM files and thresholds.")
          }

          # ---------------------------------------------------------------
          # Optional: extract enhancer sequences from reference FASTA
          # ---------------------------------------------------------------
          seqs <- NULL
          if (!is.null(genome_fasta) && length(peaks) > 0) {
            if (!file.exists(paste0(genome_fasta, ".fai"))) {
              message("WARNING: no .fai index found for ", genome_fasta,
                      ". Skipping sequence extraction.")
            } else {
              suppressPackageStartupMessages(library(Rsamtools))
              fa          <- FaFile(genome_fasta)
              fa_seqnames <- seqnames(scanFaIndex(fa))
              peak_chroms <- unique(as.character(seqnames(peaks)))
              missing     <- setdiff(peak_chroms, fa_seqnames)
              if (length(missing) > 0) {
                stop("Seqlevel mismatch: peak chromosomes [",
                     paste(missing, collapse = ", "),
                     "] not found in FASTA. Check chromosome naming (e.g. Chr1 vs chr1).")
              }
              seqs <- as.character(getSeq(fa, peaks))
              message(">>> Sequences extracted for ", length(seqs), " enhancers")
            }
          }

          # ---------------------------------------------------------------
          # Build shared data frame for both outputs
          # ---------------------------------------------------------------
          peaks_df <- as.data.frame(peaks)
          enhancer_names <- paste0(sample_name, "_enhancer_", seq_len(nrow(peaks_df)))
          # BED score: capped at 1000 per UCSC specification
          score <- pmin(1000L, as.integer(round(-log10(peaks_df$padj + .Machine$double.eps) * 100)))

          # BED: strict 6-column format for genome browsers
          bed <- data.frame(
            chrom      = peaks_df$seqnames,
            chromStart = peaks_df$start - 1L,
            chromEnd   = peaks_df$end,
            name       = enhancer_names,
            score      = score,
            strand     = peaks_df$strand
          )
          bed_file <- paste0(sample_name, "_enhancers.bed")
          write.table(bed, bed_file, sep = "\t", quote = FALSE,
                      row.names = FALSE, col.names = FALSE)
          message(">>> BED (6-column) written to: ", bed_file)

          # TSV: full annotation table for downstream ML / analysis
          basicstarrseq_version <- as.character(
            packageVersion("BasicSTARRseq"))
          message(">>> BasicSTARRseq version: ", basicstarrseq_version)

          tsv <- data.frame(
            chrom                = peaks_df$seqnames,
            chromStart           = peaks_df$start - 1L,
            chromEnd             = peaks_df$end,
            name                 = enhancer_names,
            length               = peaks_df$end - (peaks_df$start - 1L),
            sampleCov            = peaks_df$sampleCov,
            controlCov           = peaks_df$controlCov,
            pVal                 = peaks_df$pVal,
            padj                 = peaks_df$padj,
            enrichment           = peaks_df$enrichment,
            reference_genome     = reference_genome,
            basicstarrseq_version = basicstarrseq_version
          )
          if (!is.null(seqs)) {
            tsv$GC_content <- round(ifelse(
              nchar(seqs) == 0, NA_real_,
              nchar(gsub("[^GCgc]", "", seqs)) / nchar(seqs)), 4)
            tsv$sequence <- seqs
          }
          tsv_file <- paste0(sample_name, "_enhancers.tsv")
          write.table(tsv, tsv_file, sep = "\t", quote = FALSE,
                      row.names = FALSE, col.names = TRUE)
          message(">>> TSV (full annotation) written to: ", tsv_file)

          # Save GRanges as RDS for downstream R analyses
          rds_file <- paste0(sample_name, "_enhancers.rds")
          saveRDS(peaks, rds_file)
          message(">>> GRanges saved to: ", rds_file)

inputs:
  sample_bam:
    type: File
    secondaryFiles: .bai
    inputBinding:
      position: 1
    doc: cDNA BAM file (reporter transcripts)
  control_bam:
    type: File
    secondaryFiles: .bai
    inputBinding:
      position: 2
    doc: Input DNA BAM file (plasmid library)
  sample_name:
    type: string
    inputBinding:
      position: 3
    doc: Sample name prefix for output files
  paired_end:
    type: boolean
    default: false
    inputBinding:
      position: 4
    doc: Whether libraries are paired-end
  min_quantile:
    type: float?
    default: 0.9
    inputBinding:
      position: 5
    doc: Quantile of coverage used as peak threshold (BasicSTARRseq minQuantile)
  peak_width:
    type: int?
    default: 500
    inputBinding:
      position: 6
    doc: Width in bp assigned to each called peak (BasicSTARRseq default)
  max_padj:
    type: float?
    default: 0.01
    inputBinding:
      position: 7
    doc: Maximum BH-adjusted p-value for an enhancer to be retained (paper threshold)
  min_enrichment:
    type: float?
    default: 1.3
    inputBinding:
      position: 8
    doc: Minimum cDNA/input enrichment ratio (paper threshold)
  deduplicate:
    type: boolean?
    default: true
    inputBinding:
      position: 9
    doc: Deduplicate reads inside BasicSTARRseq before peak calling
  model:
    type: int?
    default: 1
    inputBinding:
      position: 10
    doc: >-
      Binomial model for p-value calculation.
      Model 1 (default): trials = total STARR-seq reads, success prob = input_cov/total_input.
      Model 2: as in Arnold et al. 2013 Science.
  genome_fasta:
    type: File?
    secondaryFiles: .fai
    inputBinding:
      position: 11
      valueFrom: $(self ? self.path : "")
    doc: >-
      Optional indexed reference FASTA (.fa + .fai). When provided, the
      sequence of each enhancer is extracted and added to the TSV output,
      together with length and GC_content, producing a training-ready file.
  reference_genome:
    type: string?
    default: "unknown"
    inputBinding:
      position: 12
    doc: >-
      Reference genome assembly identifier recorded in the TSV (e.g. TAIR10,
      UCSC_TAIR10.1). Used for provenance when merging datasets.

outputs:
  enhancers_bed:
    type: File
    outputBinding:
      glob: $(inputs.sample_name + "_enhancers.bed")
    doc: >-
      Strict 6-column BED file (chrom, chromStart, chromEnd, name,
      score=-log10(padj), strand) for genome browsers and BED-aware tools.
  enhancers_tsv:
    type: File
    outputBinding:
      glob: $(inputs.sample_name + "_enhancers.tsv")
    doc: >-
      Tab-separated file with headers for downstream ML / analysis.
      Columns: chrom, chromStart, chromEnd, name, length, sampleCov,
      controlCov, pVal, padj, enrichment, reference_genome,
      basicstarrseq_version [, GC_content, sequence if genome_fasta provided].
      This is the canonical training-ready output.
  enhancers_rds:
    type: File
    outputBinding:
      glob: $(inputs.sample_name + "_enhancers.rds")
    doc: GRanges object saved as RDS for downstream R analyses

baseCommand: ["Rscript", "--vanilla", "basicstarrseq.R"]
