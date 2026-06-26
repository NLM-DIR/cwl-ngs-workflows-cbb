#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: readQC
doc: NGS read Quality Control analysis

hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/bioconductor-diffbind:3.16.0--r44h77050f0_0
  SoftwareRequirement:
    packages:
      - package: 'bioconductor-diffbind'
        version:
          - '3.16.0'
        specs:
          - https://anaconda.org/bioconda/bioconductor-diffbind

requirements:
  ResourceRequirement:
    ramMin: 512
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: readQC.R
        entry: |
          args = commandArgs(trailingOnly=TRUE)
          if (!require("ggplot2", quietly = TRUE)) {
            message("ggplot2 not found. Installing...")
            install.packages("ggplot2", repos = "https://cloud.r-project.org")
          }
          if (!require("dplyr", quietly = TRUE)) {
            message("dplyr not found. Installing...")
            install.packages("dplyr", repos = "https://cloud.r-project.org")
          }
          suppressPackageStartupMessages({
            library(ggplot2)
            library(dplyr)
          })
          
          tags=args[1]
          if(!dir.exists(tags)) {
            stop("ERROR: Tag folder not found")
          }
          sample_name = basename(tags)
          ## Tag count uniqueness ##ss
          tcount = read.table(paste0(tags,"/tagCountDistribution.txt"), header = T, sep = "\t")
          colnames(tcount) = c("Alignments", "Fraction")
          tcount = tcount[tcount[,1] <= 10,]
          tcount = tcount[tcount[,1] > 0,]
          pdf(paste0(sample_name, "_Uniqueness.pdf"))
          ggplot(data = tcount, aes(x=Alignments, y=Fraction)) +
            geom_line(stat="identity", linetype = "dashed") +
            scale_y_continuous(limits = c(0,1)) +
            scale_x_continuous(breaks = c(1:10)) +
            xlab("No. secondary alignments") +
            theme_classic() +
            geom_point()
          dev.off()
          ## Peak size and FPKM stats END ##
          ## Autocorrelation analysis ##
          acorr = read.table(paste0(tags,"/tagAutocorrelation.txt"), header = T, sep = "\t")
          colnames(acorr) = c("Distance", "Same_strand", "Opposite_strand")
          df = acorr
          df[,3] = NULL
          colnames(df) = c("Distance", "Total")
          df$type="Same strand"
          acorr[,2] = NULL
          colnames(acorr) = c("Distance", "Total")
          acorr$type="Opposite strand"
          df = rbind(df, acorr)
          distances = c("2000", "1000", "500", "250", "200")
          for(i in 1:length(distances)) {
            df = df[df[,1] >= -as.numeric(distances[i]) & df[,1] <= as.numeric(distances[i]),]
            pdf(paste0(sample_name,"_Autocorrelation_", distances[i], "dist.pdf"))
            p1 = ggplot(data = df, aes(x=Distance, y=Total, group=type)) +
              geom_line(aes(color=type)) +
              theme_classic()
            plot(p1)
            dev.off()
          }
          ## Autocorrelation analysis END ##
          ## Tag length distro analysis ##
          tlen = read.table(paste0(tags,"/tagLengthDistribution.txt"), header = T, sep = "\t")
          colnames(tlen) = c("Length", "Fraction")
          tlen$type="standard"
          df = tlen
          df$Fraction = cumsum(df$Fraction)
          df$type="cumulative"
          df = rbind(df, tlen)
          pdf(paste0(sample_name, "_Length_distribution.pdf"))
          ggplot(data = df, aes(x=Length, y=Fraction, group=type)) +
            geom_line(aes(color=type)) +
            geom_point(aes(color=type)) +
            theme_classic()
          dev.off()
          ## Tag length distro analysis END ##
          ## GC content analysis ##
          genomeGC = read.table(paste0(tags,"/genomeGCcontent.txt"), header = T, sep = "\t")
          sampleGC = read.table(paste0(tags,"/tagGCcontent.txt"), header = T, sep = "\t")
          colnames(genomeGC) = c("GC", "Total", "Normalized")
          colnames(sampleGC) = c("GC", "Total", "Normalized")
          genomeGC$type="Genome"
          sampleGC$type="Sample"
          df = rbind(genomeGC, sampleGC)
          pdf(paste0(sample_name, "_GC_content.pdf"))
          ggplot(data=df, aes(x=GC, y=Normalized, group=type)) +
            geom_line(aes(color=type)) +
            geom_point(aes(color=type)) +
            theme_classic()
          dev.off()
          ## GC content analysis end ##

inputs:
  tags_directory:
    type: Directory
    inputBinding:
      position: 1

outputs:
  plots:
    type: File[]
    outputBinding:
      glob: "*.pdf"

baseCommand: ["Rscript", "--vanilla", "readQC.R"]
