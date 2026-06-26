class: Workflow
cwlVersion: v1.0

id: idr
doc: Irreproducible Discovery Rate (IDR) workflow with Homer annotation
label: IDR workflow

requirements: 
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  narrowpeaks:
    type: {"type": "array", "items": {"type": "array", "items": "File"}}
  rank: string
  soft_idr_threshold: float?
  input_file_type: string
  genome_fasta: File
  genome_gtf: File?
  output_file: string[]
  pooled_peak_list: File[]

outputs:
  output:
    outputSource: homer_annotate_peaks_file/output
    type: File[]
  annStats_out:
    outputSource: homer_annotate_peaks_file/annStats_out
    type: File[]?
  plots:
    outputSource: idr/plots
    type: {"type": "array", "items": {"type": "array", "items": "File"}}
  idr_peaks:
    outputSource: idr/idr_peaks
    type: File[]

steps:
  idr:
    run: ../../tools/idr/idr.cwl
    label: idr
    scatter: [samples, output_file, peak_list]
    scatterMethod: dotproduct
    in:
      input_file_type: input_file_type
      output_file: output_file
      peak_list: pooled_peak_list
      plot: { default: true }
      rank: rank
      samples: narrowpeaks
      soft_idr_threshold: soft_idr_threshold
      use_best_multisummit_IDR: {default: true}
    out: [idr_peaks, plots]
  homer_make_tag_directory:
    run: ../../tools/homer/homer-makeTagDirectory.cwl
    label: HOMER-makeTagDirectory
    scatter: input
    in:
      checkGC: { default: true}
      format: { default: bed}
      genome: genome_fasta
      input: idr/idr_peaks
      tags_directory_name:
        valueFrom: ' ${ return inputs.input.nameroot + "_tags";}'
    out: [tags_directory]
  homer_annotate_peaks_file:
    run: ../../tools/homer/homer-annotatePeaks.cwl
    scatter: [input, d]
    scatterMethod: dotproduct
    in:
      annStats:
        valueFrom: '${ return inputs.input.basename + "_annStats.txt";}'
      d: homer_make_tag_directory/tags_directory
      fpkm: { default: true}
      genome: genome_fasta
      gtf: genome_gtf
      input: idr/idr_peaks
      o:
        valueFrom: '${ return inputs.input.basename + "_annotation.txt";}'
    out: [annStats_out, output]
