class: Workflow
cwlVersion: v1.2

id: create_pseudo_replicates
doc: Create pseudo replicates with samtools
label: Create Pseudo replicates with samtools

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  bam: File
  seed: float
  threads: int

outputs:
  bam_A:
    outputSource: index_bam_A/out_sam
    type: File
    secondaryFiles: [ .bai ]
  bed_A:
    outputSource: bamtobed_A/out_stdout
    type: File
  bam_B:
    outputSource: index_bam_B/out_sam
    type: File
    secondaryFiles: [ .bai ]
  bed_B:
    outputSource: bamtobed_B/out_stdout
    type: File

steps:
  extract_header:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: bam
      H: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + "_header.sam";}'
    out: [ output ]
  convert_sam:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: bam
      samheader: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".sam";}'
      threads: threads
    out: [ output ]
  create_pseudo:
    in:
      sam_file: convert_sam/output
      prefix:
        valueFrom: '${ return inputs.sam_file.nameroot;}'
    out: [ samA, samB ]
    run:
      class: CommandLineTool
      requirements:
        InlineJavascriptRequirement: { }
      inputs:
        sam_file:
          type: File
          inputBinding:
            position: 2
        prefix:
          type: string?
          inputBinding:
            position: 1
            valueFrom: |
              ${                  
                  return 'BEGIN{srand(42)} /^@/ {print; next} {if (rand() <= 0.5) print > "' + inputs.prefix + '_A_reads.sam"; else print > "' + inputs.prefix + '_B_reads.sam"}'
              }

      outputs:
        samA:
          type: File
          outputBinding:
            glob: |
              ${
                return inputs.prefix + '_A_reads.sam';
              }
        samB:
          type: File
          outputBinding:
            glob: |
              ${
                return inputs.prefix + '_B_reads.sam';
              }
      baseCommand: ["awk"]
  add_header_A:
    in:
      sam_header: extract_header/output
      sam: create_pseudo/samA
      output:
        valueFrom: '${ return inputs.sam.nameroot.replace("_reads.sam", ".sam");}'
    out: [ sam ]
    run:
      class: CommandLineTool
      requirements:
        InlineJavascriptRequirement: { }
      inputs:
        sam_header:
          type: File
          inputBinding:
            position: 1
        output:
          type: string
        sam:
          type: File
          inputBinding:
            position: 2
      outputs:
        sam:
          type: stdout
      stdout: $(inputs.output)
      baseCommand: ["cat"]
  bam_A:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: add_header_A/sam
      isbam: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".bam";}'
      threads: threads
    out: [ output ]
  sort_bam_A:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: bam_A/output
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_sorted.bam";}'
      threads: threads
    out: [ out_sam ]
  index_bam_A:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: sort_bam_A/out_sam
    out: [ out_sam ]
  bamtobed_A:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    in:
      i: index_bam_A/out_sam
      stdout:
        valueFrom: '${ return inputs.i.nameroot + ".bed";}'
    out: [ out_stdout ]
  add_header_B:
    in:
      sam_header: extract_header/output
      sam: create_pseudo/samB
      output:
        valueFrom: '${ return inputs.sam.nameroot.replace("_reads.sam", ".sam");}'
    out: [ sam ]
    run:
      class: CommandLineTool
      requirements:
        InlineJavascriptRequirement: { }
      inputs:
        sam_header:
          type: File
          inputBinding:
            position: 1
        output:
          type: string
        sam:
          type: File
          inputBinding:
            position: 2
      outputs:
        sam:
          type: stdout
      stdout: $(inputs.output)
      baseCommand: [ "cat" ]
  bam_B:
    run: ../../tools/samtools/samtools-view.cwl
    label: Samtools-view
    in:
      input: add_header_B/sam
      isbam: { default: true }
      output_name:
        valueFrom: '${ return inputs.input.nameroot + ".bam";}'
      threads: threads
    out: [ output ]
  sort_bam_B:
    run: ../../tools/samtools/samtools-sort.cwl
    label: Samtools-sort
    in:
      in_bam: bam_B/output
      out_bam:
        valueFrom: '${ return inputs.in_bam.nameroot + "_sorted.bam";}'
      threads: threads
    out: [ out_sam ]
  index_bam_B:
    run: ../../tools/samtools/samtools-index.cwl
    label: Samtools-index
    in:
      in_bam: sort_bam_B/out_sam
    out: [ out_sam ]
  bamtobed_B:
    run: ../../tools/bedtools/bedtools-bamtobed.cwl
    label: bedtools-bamtobed
    in:
      i: index_bam_B/out_sam
      stdout:
        valueFrom: '${ return inputs.i.nameroot + ".bed";}'
    out: [ out_stdout ]
