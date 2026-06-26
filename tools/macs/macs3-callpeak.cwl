#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: MACS3-callpeak
doc: BASH echo command

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 1024

hints:
  - $import: macs3-docker.yml
  - $import: macs3-bioconda.yml

inputs:
  call-summits:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --call-summits
    doc: 'If set, MACS will use a more sophisticated signal processing approach to
        find subpeak summits in each enriched peak region. DEFAULT: False '
  f:
    type: string?
    inputBinding:
      position: 1
      prefix: --format
    doc: '-f {AUTO,BAM,SAM,BED,ELAND,ELANDMULTI,ELANDEXPORT,BOWTIE,BAMPE}, --format
        {AUTO,BAM,SAM,BED,ELAND,ELANDMULTI,ELANDEXPORT,BOWTIE,BAMPE} Format of tag file,
        "AUTO", "BED" or "ELAND" or "ELANDMULTI" or "ELANDEXPORT" or "SAM" or "BAM"
        or "BOWTIE" or "BAMPE". The default AUTO option will let MACS decide which format
        the file is. Note that MACS can''t detect "BAMPE" or "BEDPE" format with "AUTO",
        and you have to implicitly specify the format for "BAMPE" and "BEDPE". DEFAULT:
        "AUTO".'
  cutoff-analysis:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --cutoff-analysis
    doc: 'While set, MACS2 will analyze number or total length of peaks that can be
        called by different p-value cutoff then output a summary table to help user
        decide a better cutoff. The table will be saved in NAME_cutoff_analysis.txt
        file. Note, minlen and maxgap may affect the results. WARNING: May take ~30
        folds longer time to finish. DEFAULT: False Post-processing options: '
  p:
    type: float?
    inputBinding:
      position: 1
      prefix: --pvalue
    doc: 'Pvalue cutoff for peak detection. DEFAULT: not set.  -q, and -p are mutually
        exclusive. If pvalue cutoff is  set, qvalue will not be calculated and reported
        as -1  in the final .xls file..'
  p_file:
    type: File?
    inputBinding:
      position: 1
      prefix: --pvalue
      loadContents: True
      valueFrom: ${ return inputs.input.contents.split('\n')[0];}
    doc: |
      Pvalue cutoff for peak detection loaded from the first line of a file.
  q:
    type: float?
    inputBinding:
      position: 1
      prefix: --qvalue
    doc: |
      The qvalue (minimum FDR) cutoff to call significant regions. Default is 0.05
  q_file:
    type: File?
    inputBinding:
      position: 1
      prefix: --qvalue
      loadContents: True
      valueFrom: ${ return inputs.q_file.contents.split('\n')[0];}
    doc: |
      The qvalue (minimum FDR) cutoff to call significant regions loaded from the first line of a file. Default is 0.05
  B:
    type: boolean?
    inputBinding:
      position: 1
      prefix: --bdg
    doc: 'Whether or not to save extended fragment pileup, and local lambda tracks
        (two files) at every bp into a bedGraph file. DEFAULT: True'
  t:
    type: File
    inputBinding:
      position: 2
      prefix: --treatment
    doc: 'Treatment sample file(s). If multiple files are given as -t A B C, then
        they will all be read and pooled together. IMPORTANT: the first sample will
        be used as the outputs basename.'
  n:
    type: string
    inputBinding:
      position: 2
      prefix: --name
    doc: |
      The name string of the experiment. MACS will use this string NAME to create output files like
      NAME_peaks.xls, NAME_negative_peaks.xls, NAME_peaks.bed , NAME_summits.bed, NAME_model.r and so
      on. So please avoid any confliction between these filenames and your existing files
  c:
    type: File?
    inputBinding:
      position: 2
      prefix: --control
    doc: |
      The control or mock data file. Please follow the same direction as for -t/--treatment.
  g:
    type: string?
    inputBinding:
      position: 2
      prefix: --gsize
    doc: |
      It's the mappable genome size or effective genome size which is defined as the genome size which can be sequenced.
  nomodel:
    type: boolean?
    inputBinding:
      position: 2
      prefix: --nomodel
    doc: |
      While on, MACS will bypass building the shifting model.
  shift:
    type: int?
    inputBinding:
      position: 2
      prefix: --shift
    doc: |
      Note, this is NOT the legacy --shiftsize option which is replaced by --extsize! You can set an arbitrary shift in bp here.
  extsize:
    type: int?
    inputBinding:
      position: 2
      prefix: --extsize
    doc: |
      While '--nomodel' is set, MACS uses this parameter to extend reads in 5'->3' direction to fix-sized fragments
  broad:
    type: boolean?
    inputBinding:
      position: 2
      prefix: --broad
    doc: |
      When this flag is on, MACS will try to composite broad regions in BED12
  broad-cutoff:
    type: float?
    inputBinding:
      position: 2
      prefix: --broad-cutoff
    doc: |
      Cutoff for broad region. This option is not available unless --broad is set. If -p is set, this is a pvalue cutoff, otherwise, it's a qvalue cutoff. DEFAULT: 0.1
  outdir_name:
    type: string
    inputBinding:
      position: 2
      prefix: --outdir
    doc: |
      MACS2 will save all output files into speficied folder for this option

outputs:
  lambda:
    type: File
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_control_lambda.bdg
  pileup:
    type: File
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_treat_pileup.bdg
  cutoff_analysis:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_cutoff_analysis.txt
  cutoff_analysis_pdf:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_cutoff_analysis.pdf
  cutoff_analysis_inflection:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_cutoff_analysis_inflection.txt
  narrowPeak:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_peaks.narrowPeak
  xls:
    type: File
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_peaks.xls
  bed:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_summits.bed
  broadPeak:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_peaks.broadPeak
  gappedPeak:
    type: File?
    outputBinding:
      glob: $(inputs.outdir_name)/$(inputs.n)_peaks.gappedPeak


baseCommand: ["macs3","callpeak"]
