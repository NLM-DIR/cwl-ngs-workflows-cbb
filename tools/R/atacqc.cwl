#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: ATACQC
doc: Quality metrics for ATAC-seq data.

hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/__bioconductor-atacseqqc:1.30.0--r44hdfd78af_0
  SoftwareRequirement:
    packages:
      - package: 'bioconductor-atacseqqc'
        version:
          - '1.30.0'
        specs:
          - https://anaconda.org/bioconda/bioconductor-atacseqqc

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: ATACQC.R
        entry: |
          args = commandArgs(trailingOnly=TRUE)
          
          BAM_FILE <- args[1]
          ANNOT_FILE <- args[2]
          if(!file.exists(BAM_FILE)) {
            stop("ERROR: BAM file not found")
          }
          sample_name <- sub('\\..*$', '', basename(BAM_FILE))
          OUTDIR <- paste0(sample_name, "_ATACQC")
          
          MAPQ_MIN <- 30
          TSS_UPDN <- 1000
          
          dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)          
          
          ## ================================================================
          ## Install & load dependencies if missing
          ## ================================================================
          if (!requireNamespace("BiocManager", quietly = TRUE))
            install.packages("BiocManager")
          
          bioc_pkgs <- c(
            "ATACseqQC", "GenomicFeatures", "GenomicRanges",
            "Rsamtools", "GenomicAlignments", "rtracklayer", "txdbmaker"
          )
          for (pkg in bioc_pkgs) {
            if (!requireNamespace(pkg, quietly = TRUE)) {
              message("Installing missing package: ", pkg)
              BiocManager::install(pkg, update = FALSE, ask = FALSE)
            }
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
          }          
          
          ## ================================================================
          ## Load required libraries
          ## ================================================================
          suppressPackageStartupMessages({
            library(ATACseqQC)
            library(GenomicFeatures)
            library(GenomicRanges)
            library(Rsamtools)
            library(GenomicAlignments)
            library(rtracklayer)
          })
          
          ## ================================================================
          ## Build TxDb from annotation (GTF or GFF3)
          ## ================================================================
          ext <- tolower(tools::file_ext(ANNOT_FILE))
          if (!ext %in% c("gtf", "gff", "gff3")) {
            stop("Error: annotation file must be .gtf or gff or .gff3")
          }
          message(sprintf(">>> Building TxDb from %s", ANNOT_FILE))
          txdb <- makeTxDbFromGFF(ANNOT_FILE, format = ext)
          
          ## ================================================================
          ## Define TSS regions
          ## ================================================================
          TSS <- promoters(genes(txdb), upstream = 1, downstream = 0)
          TSS <- resize(TSS, width = 1, fix = "start")
          TSS <- unique(TSS)
          
          ## ================================================================
          ## Helper functions
          ## ================================================================
          tsse_for_bam <- function(bam) {
            gal <- readBamFile(bam, tag = character(), which = NULL, asMates = TRUE, bigFile = TRUE)
            gal_shift <- shiftGAlignmentsList(gal)
            tsse <- TSSEscore(gal_shift,
                              txs = promoters(genes(txdb),
                                              upstream = TSS_UPDN,
                                              downstream = TSS_UPDN))
            as.numeric(tsse$tsse)
          }
          
          nrf_for_bam <- function(bam) {
            dupfreq <- readsDupFreq(bam)
            uniq <- sum(dupfreq$uniq.frequencies)
            total <- sum(dupfreq$all.frequencies)
            uniq / total
          }
          
          ## ================================================================
          ## Run QC
          ## ================================================================
          sample_id <- tools::file_path_sans_ext(basename(BAM_FILE))
          prefix <- file.path(OUTDIR, sample_id)
          
          message(sprintf(">>> Processing sample: %s\n", sample_id))
          
          # 1. Fragment size distribution
          pdf(paste0(prefix, "_fragSizeDist.pdf"), width = 6, height = 4)
          try(fragSizeDist(bamFiles = BAM_FILE, bamFiles.labels = sample_id))
          dev.off()
          
          # 2. TSS meta-profile (no splitBam required)
          pdf(paste0(prefix, "_TSS_meta_profile.pdf"), width = 6, height = 4)
          try({
            tss_win <- promoters(genes(txdb), upstream = TSS_UPDN, downstream = TSS_UPDN)
            sig <- featureAlignedSignal(bamFiles = BAM_FILE,
                                        feature = tss_win,
                                        upstream = TSS_UPDN,
                                        downstream = TSS_UPDN,
                                        n.tile = 100)
            plotAvgProf(sig,
                        xlab = "Distance to TSS (bp)",
                        ylab = "Normalized coverage",
                        main = paste0(sample_id, " TSS meta-profile"))
          }, silent = TRUE)
          dev.off()
          
          # 4. Compute TSSE and NRF metrics
          tsse <- try(tsse_for_bam(BAM_FILE), silent = TRUE)
          tsse <- if (inherits(tsse, "try-error")) NA_real_ else tsse
          
          nrf <- try(nrf_for_bam(BAM_FILE), silent = TRUE)
          nrf <- if (inherits(nrf, "try-error")) NA_real_ else nrf
          
          ## ================================================================
          ## Write summary
          ## ================================================================
          qc_summary <- data.frame(
            sample_id = sample_id,
            TSSE = tsse,
            NRF = nrf
          )
          out_file <- file.path(OUTDIR, "qc_summary.tsv")
          write.table(qc_summary, out_file, sep = "\t", quote = FALSE, row.names = FALSE)
          
          message(sprintf("QC completed for %s\n", sample_id))
          message(sprintf("Results written to: %s\n", out_file))
          message(sprintf("Plots saved in: %s\n", OUTDIR))
          

inputs:
  bam:
    type: File
    secondaryFiles: .bai
    inputBinding:
      position: 1
  annotation:
    type: File
    inputBinding:
      position: 2

outputs:
  report:
    type: Directory
    outputBinding:
      glob: $(inputs.bam.nameroot + '_ATACQC')

baseCommand: ["Rscript", "--vanilla", "ATACQC.R"]