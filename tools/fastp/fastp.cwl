cwlVersion: v1.2
class: CommandLineTool

label: fastp
doc: Fastp trimming tool

requirements:
  InlineJavascriptRequirement: { }
  ResourceRequirement:
    coresMin: $(inputs.thread)


hints:
  - $import: fastp-docker.yml
  - $import: fastp-bioconda.yml

inputs:
  thread:
    type: int?
    default: 1
    inputBinding:
      position: 1
      prefix: --thread
  in1:
    type: File
    inputBinding:
      position: 2
      prefix: --in1
  out1:
    type: string
    inputBinding:
      position: 3
      prefix: --out1
  in2:
    type: File?
    inputBinding:
      position: 4
      prefix: --in2
  out2:
    type: string?
    inputBinding:
      position: 5
      prefix: --out2
  merge:
    type: boolean?
    inputBinding:
      position: 6
      prefix: --merge
  phred64:
    type: boolean?
    inputBinding:
      position: 7
      prefix: --phred64
  compression:
    type: int?
    inputBinding:
      position: 8
      prefix: --compression
  interleaved_in:
    type: boolean?
    inputBinding:
      position: 9
      prefix: --interleaved_in
  adapter_sequence:
    type: string?
    inputBinding:
      position: 10
      prefix: --adapter_sequence
  adapter_sequence_r2:
    type: string?
    inputBinding:
      position: 11
      prefix: --adapter_sequence_r2
  adapter_fasta:
    type: File?
    inputBinding:
      position: 12
      prefix: --adapter_fasta
  detect_adapter_for_pe:
    type: boolean?
    inputBinding:
      position: 13
      prefix: --detect_adapter_for_pe
  trim_front1:
    type: int?
    inputBinding:
      position: 14
      prefix: --trim_front1
  trim_tail1:
    type: int?
    inputBinding:
      position: 15
      prefix: --trim_tail1
  max_len1:
    type: int?
    inputBinding:
      position: 16
      prefix: --max_len1
  trim_front2:
    type: int?
    inputBinding:
      position: 17
      prefix: --trim_front2
  trim_tail2:
    type: int?
    inputBinding:
      position: 18
      prefix: --trim_tail2
  max_len2:
    type: int?
    inputBinding:
      position: 19
      prefix: --max_len2
  trim_poly_g:
    type: boolean?
    inputBinding:
      position: 20
      prefix: --trim_poly_g
  poly_g_min_len:
    type: int?
    inputBinding:
      position: 21
      prefix: --poly_g_min_len
  disable_trim_poly_g:
    type: boolean?
    inputBinding:
      position: 22
      prefix: --disable_trim_poly_g
  trim_poly_x:
    type: boolean?
    inputBinding:
      position: 23
      prefix: --trim_poly_x
  poly_x_min_len:
    type: int?
    inputBinding:
      position: 24
      prefix: --poly_x_min_len
  cut_front:
    type: boolean?
    inputBinding:
      position: 25
      prefix: --cut_front
  cut_tail:
    type: boolean?
    inputBinding:
      position: 26
      prefix: --cut_tail
  cut_right:
    type: boolean?
    inputBinding:
      position: 27
      prefix: --cut_right
  cut_window_size:
    type: int?
    inputBinding:
      position: 28
      prefix: --cut_window_size
  cut_mean_quality:
    type: int?
    inputBinding:
      position: 29
      prefix: --cut_mean_quality
  average_qual:
    type: int?
    inputBinding:
      position: 30
      prefix: --average_qual
  length_required:
    type: int?
    inputBinding:
      position: 31
      prefix: --length_required
  umi:
    type: boolean?
    inputBinding:
      position: 32
      prefix: --umi
  umi_loc:
    type: string?
    inputBinding:
      position: 33
      prefix: --umi_loc
    doc: specify the location of UMI, can be (index1/index2/read1/read2/per_index/per_read, default is none (string [=])
  umi_len:
    type: int?
    inputBinding:
      position: 34
      prefix: --umi_len
    doc: if the UMI is in read1/read2, its length should be provided (int [=0])
  umi_prefix:
    type: string?
    inputBinding:
      position: 35
      prefix: --umi_prefix
    doc: if specified, an underline will be used to connect prefix and UMI (i.e. prefix=UMI, UMI=AATTCG, final=UMI_AATTCG). No prefix by default (string [=])
  umi_skip:
    type: int?
    inputBinding:
      position: 36
      prefix: --umi_skip
    doc: if the UMI is in read1/read2, fastp can skip several bases following UMI, default is 0 (int [=0])
  umi_delim:
    type: string?
    inputBinding:
      position: 37
      prefix: --umi_delim
    doc: delimiter to use between the read name and the UMI, default is (string [=:])
  json:
    type: string?
    inputBinding:
      position: 38
      prefix: --json

outputs:
  r1:
    type: File
    outputBinding:
      glob: $(inputs.out1)
  r2:
    type: File?
    outputBinding:
      glob: $(inputs.out2)
  r:
    type: File?
    outputBinding:
      glob: $(inputs.json)

baseCommand: [ fastp ]
