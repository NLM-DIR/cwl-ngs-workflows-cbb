#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: idr
doc: Irreproducible Discovery Rate (IDR)

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

hints:
  - $import: idr-docker.yml
  - $import: idr-bioconda.yml

inputs:
    samples:
        type: File[]
        inputBinding:
            position: 1
            prefix: --samples
        doc: |
            Files containing peaks and scores.
    peak_list:
        type: File?
        inputBinding:
            position: 2
            prefix: --peak-list
        doc: |
            If provided, all peaks will be taken from this file.
    input_file_type:
        type: string
        inputBinding:
            position: 3
            prefix: --input-file-type
        doc: |
            File type of --samples and --peak-list: narrowPeak, broadPeak, bed, gff
    output_file:
        type: string
        inputBinding:
            position: 4
            prefix: --output-file
        doc: |
            File to write output to.
    output_file_type:
        type: string?
        inputBinding:
            position: 5
            prefix: --output-file-type
        doc: |
            Output file type. Defaults to input file type when available, otherwise bed.
    idr_threshold:
        type: float?
        inputBinding:
            position: 6
            prefix: --idr-threshold
        doc: |
            Only return peaks with a global idr threshold below this value.
            Default: report all peaks
    soft_idr_threshold:
        type: float?
        inputBinding:
            position: 7
            prefix: --soft-idr-threshold
        doc: |
            Report statistics for peaks with a global idr below this value but return all peaks with an idr below --idr.
            Default: 0.05
    plot:
        type: boolean?
        inputBinding:
            position: 8
            prefix: --plot
        doc: |
            Plot the results to [OFNAME].png
    rank:
        type: string?
        inputBinding:
            position: 9
            prefix: --rank
        doc: |
            Options: signal.value p.value q.value columnIndex
            Defaults:
                narrowPeak/broadPeak: signal.value
                bed: score
    use_best_multisummit_IDR:
        type: boolean?
        inputBinding:
            position: 10
            prefix: --use-best-multisummit-IDR
        doc: |
            Set the IDR value for a group of multi summit peaks (a group of peaks with the same chr/start/stop but
            different summits) to the best value across all of these peaks. This is a work around for peak callers
            that don't do a good job splitting scores across multi summit peaks (e.g. MACS).
            If set in conjunction with --plot two plots will be created - one with alternate summits and
            one without.  Use this option with care.

outputs:
    idr_peaks:
        type: File
        outputBinding:
          glob: $(inputs.output_file)
    plots:
        type: File[]
        outputBinding:
          glob: $(inputs.output_file)*.png

baseCommand: ["idr"]
