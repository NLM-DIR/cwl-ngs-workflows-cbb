#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: MACS2_cutoff
doc: Inflection point calculated from MACS2 peaks file

hints:
  - $import: diffbind-docker.yml
  - $import: diffbind-bioconda.yml

requirements:
  ResourceRequirement:
    ramMin: 1024
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: MACScutoff.R
        entry: |
          args = commandArgs(trailingOnly=TRUE)
          if (!require("ggplot2", quietly = TRUE)) {
            message("ggplot2 not found. Installing...")
            install.packages("ggplot2", repos = "https://cloud.r-project.org")
          }
          suppressPackageStartupMessages({
            library(ggplot2)
          })
          peak_cutoff_file = args[1]
          out_pdf = args[2]
          out_inflection = args[3]
          cutoff = read.table(peak_cutoff_file, header = T, sep = "\t", stringsAsFactors = F, check.names = F)
          cutoff$lognpeak = log10(cutoff$npeaks)
          cutoff$index= 1:nrow(cutoff)
          cutoff$infl = predict(loess(cutoff$lognpeak ~ cutoff$index))
          cutoff$diff = c(0, diff(cutoff$infl))
          cutoff$diff2 = c(0, diff(cutoff$diff))
          cutoff$diff2[2] = 0
          inflpoint = cutoff[cutoff$diff2 == max(cutoff$diff2),][[1]]
          p1 = ggplot(data=cutoff, aes(x=pscore, y=npeaks, group=1)) +
              geom_line()+
              geom_point() +
              scale_y_continuous(trans='log2') +
              geom_vline(xintercept = inflpoint, color = "red", linetype = "dotted") +
              geom_smooth(method = 'loess') +
              geom_line() +
              ylab("log10(number of peaks)") +
              xlab("log10(p-value)") +
              theme_bw()
          pdf(out_pdf)
          plot(p1)
          dev.off()
          write.table(10^-inflpoint, out_inflection, quote = F, row.names = F, col.names = F)

inputs:
  peak_cutoff_file:
    type: File
    inputBinding:
      position: 1
  out_pdf_name:
    type: string
    inputBinding:
      position: 2
  out_inflection_name:
    type: string
    inputBinding:
      position: 3

outputs:
  out_pdf:
    type: File
    outputBinding:
      glob: $(inputs.out_pdf_name)
  out_inflection:
    type: File
    outputBinding:
      glob: $(inputs.out_inflection_name)

baseCommand: ["Rscript", "--vanilla", "MACScutoff.R"]
