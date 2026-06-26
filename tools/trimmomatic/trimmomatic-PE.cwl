class: CommandLineTool
cwlVersion: v1.2

label: Trimmomatic
doc: >
  Trimmomatic is a fast, multithreaded command line tool that can be used to
  trim and crop

  Illumina (FASTQ) data as well as to remove adapters

requirements:
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
  - class: SchemaDefRequirement
    types:
      - name: end_mode
        symbols:
          - SE
          - PE
        type: enum
      - fields:
          - name: windowSize
            type: int
          - name: requiredQuality
            type: int
        name: slidingWindow
        type: record
      - name: phred
        symbols:
          - '64'
          - '33'
        type: enum
      - fields:
          - doc: >
              FASTA file containing adapters, PCR sequences, etc. It is used to
              search

              for and remove these sequences in the input FASTQ file(s)
            name: adapters
            type: File
          - doc: >
              specifies the maximum mismatch count which will still allow a full
              match

              to be performed
            name: seedMismatches
            type: int
          - doc: >
              specifies how accurate the match between the two 'adapter ligated'
              reads

              must be for PE palindrome read alignment.
            name: palindromeClipThreshold
            type: int
          - doc: >
              specifies how accurate the match between any adapter etc. sequence
              must

              be against a read
            name: simpleClipThreshold
            type: int
          - doc: >
              In addition to the alignment score, palindrome mode can verify
              that a

              minimum length of adapter has been detected. If unspecified, this

              defaults to 8 bases, for historical reasons. However, since
              palindrome

              mode has a very low false positive rate, this can be safely
              reduced, even

              down to 1, to allow shorter adapter fragments to be removed.
            name: minAdapterLength
            type: int?
          - doc: >
              After read-though has been detected by palindrome mode, and the
              adapter

              sequence removed, the reverse read contains the same sequence
              information

              as the forward read, albeit in reverse complement. For this
              reason, the

              default behaviour is to entirely drop the reverse read. By
              specifying

              "true" for this parameter, the reverse read will also be retained,
              which

              may be useful e.g. if the downstream tools cannot handle a
              combination of

              paired and unpaired reads.
            name: keepBothReads
            type: boolean?
        name: illuminaClipping
        type: record
      - fields:
          - name: targetLength
            type: int
          - name: strictness
            type: int
        name: maxinfo
        type: record
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

hints:
  - $import: trimmomatic-docker.yml
  - $import: trimmomatic-bioconda.yml

inputs:
  - id: avgqual
    type: int?
    inputBinding:
      position: 20
      prefix: 'AVGQUAL:'
      separate: false
    doc: |
      Drop the read if the average quality is below the specified level
  - id: crop
    type: int?
    inputBinding:
      position: 19
      prefix: 'CROP:'
      separate: false
    doc: >
      Removes bases regardless of quality from the end of the read, so that the

      read has maximally the specified length after this step has been

      performed. Steps performed after CROP might of course further shorten the

      read. The value is the number of bases to keep, from the start of the
      read.
  - id: headcrop
    type: int?
    inputBinding:
      position: 18
      prefix: 'HEADCROP:'
      separate: false
    doc: |
      Removes the specified number of bases, regardless of quality, from the
      beginning of the read.
      The numbser specified is the number of bases to keep, from the start of
      the read.
  - id: illuminaClip
    type: string?
    inputBinding:
      position: 11
      valueFrom: |
        ${
            return 'ILLUMINACLIP:' + self;
         }
    doc: Cut adapter and other illumina-specific sequences from the read.
  - id: leading
    type: int?
    inputBinding:
      position: 20
      prefix: 'LEADING:'
      separate: false
    doc: |
      Remove low quality bases from the beginning. As long as a base has a
      value below this threshold the base is removed and the next base will be
      investigated.
  - id: maxinfo
    type: int?
    inputBinding:
      position: 15
      valueFrom: |
        ${ if ( self ) {
             return "MAXINFO:" + self.targetLength + ":" + self.strictness;
           } else {
             return self;
           }
         }
    doc: |
      Performs an adaptive quality trim, balancing the benefits of retaining
      longer reads against the costs of retaining bases with errors.
      <targetLength>: This specifies the read length which is likely to allow
      the location of the read within the target sequence to be determined.
      <strictness>: This value, which should be set between 0 and 1, specifies
      the balance between preserving as much read length as possible vs.
      removal of incorrect bases. A low value of this parameter (<0.2) favours
      longer reads, while a high value (>0.8) favours read correctness.
  - id: minlen
    type: int?
    inputBinding:
      position: 22
      prefix: 'MINLEN:'
      separate: false
    doc: |
      This module removes reads that fall below the specified minimal length.
      If required, it should normally be after all other processing steps.
      Reads removed by this step will be counted and included in the "dropped
      reads" count presented in the trimmomatic summary.
  - id: phred
    type: int?
    inputBinding:
      position: 3
      prefix: '-phred'
      separate: false
    doc: |
      "33" or "64" specifies the base quality encoding. Default: 64
  - id: input_files
    type: File[]
    inputBinding:
      position: 4
    doc: Array of FASTQ files
  - id: trimmomatic_options
    type: string?
    default: ""
    inputBinding:
      shellQuote: false
      position: 5
      valueFrom: |
        ${
           var listing = "";
           var nameroot = inputs.input_files[0].nameroot;
           for (var i = 0; i < inputs.input_files.length; i++) {
              var nameroot = inputs.input_files[i].nameroot;
              if (nameroot.endsWith(".fastq")){
                 nameroot = nameroot.replace(".fastq", "")
              }else if (nameroot.endsWith(".fq")){
                 nameroot = nameroot.replace(".fq", "")
              }
              if (nameroot.endsWith("_1")){
                 nameroot = nameroot.slice(0, -2);
                 listing += nameroot + "_1.fastq.gz "
                 listing += nameroot + "_U_1.fastq.gz ";
              }else if (nameroot.endsWith("_2")){
                 nameroot = nameroot.slice(0, -2);
                 listing += nameroot + "_2.fastq.gz "
                 listing += nameroot + "_U_2.fastq.gz ";
              }else if (nameroot.includes("_R1_") || nameroot.includes("_R2_")){
                 listing += nameroot + ".fastq.gz "
                 listing += nameroot + "_U.fastq.gz ";
              }
           }
           return listing;
         }
  - id: slidingwindow
    type: slidingWindow?
    inputBinding:
      position: 15
      valueFrom: |
        ${ if ( self ) {
             return "SLIDINGWINDOW:" + self.windowSize + ":"
               + self.requiredQuality;
           } else {
             return self;
           }
         }
    doc: |
      Perform a sliding window trimming, cutting once the average quality
      within the window falls below a threshold. By considering multiple
      bases, a single poor quality base will not cause the removal of high
      quality data later in the read.
      <windowSize> specifies the number of bases to average across
      <requiredQuality> specifies the average quality required
  - id: threads
    type: int
    inputBinding:
      position: 2
      prefix: '-threads'
  - id: tophred33
    type: boolean?
    inputBinding:
      position: 12
      prefix: TOPHRED33
      separate: false
    doc: This (re)encodes the quality part of the FASTQ file to base 33.
  - id: tophred64
    type: boolean?
    inputBinding:
      position: 12
      prefix: TOPHRED64
      separate: false
    doc: This (re)encodes the quality part of the FASTQ file to base 64.
  - id: trailing
    type: int?
    inputBinding:
      position: 20
      prefix: 'TRAILING:'
      separate: false
    doc: |
      Remove low quality bases from the end. As long as a base has a value
      below this threshold the base is removed and the next base (which as
      trimmomatic is starting from the 3' prime end would be base preceding
      the just removed base) will be investigated. This approach can be used
      removing the special Illumina "low quality segment" regions (which are
      marked with quality score of 2), but we recommend Sliding Window or
      MaxInfo instead
outputs:
  - id: trimmed
    type: File[]
    outputBinding:
      glob: |
        ${
            var files = [];
            for(var i = 0; i < inputs.input_files.length; i++){
               var nameroot = inputs.input_files[i].nameroot;
               if (nameroot.endsWith(".fastq")){
                  nameroot = nameroot.replace(".fastq", "")
               }else if (nameroot.endsWith(".fq")){
                  nameroot = nameroot.replace(".fq", "")
               }
               if (nameroot.endsWith("_1")){
                  nameroot = nameroot.slice(0, -2);
                  files.push(nameroot + "_1.fastq.gz");
               }else if (nameroot.endsWith("_2")){
                  nameroot = nameroot.slice(0, -2);
                  files.push(nameroot + "_2.fastq.gz");
               }else if (nameroot.includes("_R1_") || nameroot.includes("_R2_")){
                  nameroot = nameroot + ".fastq.gz"
                  files.push(nameroot);
               }
            }
            return files;
         }
  - id: error
    type: File[]
    outputBinding:
      glob: "*_U_*.fastq.gz"

baseCommand:
  - trimmomatic
  - PE
