cwlVersion: v1.2
class: ExpressionTool

label: stringlist2filelist
doc: From a list of file names prefix return a list of files using the extension

requirements:
  - class: InlineJavascriptRequirement
  - class: SchemaDefRequirement
    types:
      - fields:
          - doc: Fastq file for read 1
            name: read_1
            type: File
          - doc: Fastq file for read 2
            name: read_2
            type: File
        name: fastq
        type: record



hints:
  - $import: ubuntu-docker.yml

inputs:
  stringlist:
    type: string[]
  extension:
    type: string
  file_dir:
    type: Directory

outputs:
  files:
    type: File[]

expression:
  "${
      var files = [];
      var l = inputs.file_dir.listing;
      var n = l.length;
      var k = inputs.stringlist.length;
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < k; j++){
          if (l[i].basename.startsWith(inputs.stringlist[j]) && l[i].basename.endsWith(inputs.extension)) {
            files.push(l[i]);
          }
        }
      }
      return { 'files': files};

  }"
