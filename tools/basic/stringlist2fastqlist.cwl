cwlVersion: v1.2
class: ExpressionTool

label: stringlist2filelist
doc: From a list of file names prefix return a list of files using the extension

requirements:
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../types/fastq.yaml

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
    type: ../../types/fastq.yaml#fastq[]

expression:
  "${
      var files = [];
      var l = inputs.file_dir.listing;
      var n = l.length;
      var k = inputs.stringlist.length;
      for (var j = 0; j < k; j++) {
        var reads = [];
        for (var i = 0; i < n; i++){
          if (l[i].basename.startsWith(inputs.stringlist[j]) && l[i].basename.endsWith(inputs.extension)) {
            reads.push(l[i]);
          }
        }
        if (reads.length != 0){
          var fastq = {};
          if (reads.length == 1){
            fastq['read_1'] = reads[0];
          }else if (reads.length == 2){
            fastq['read_1'] = reads[0];
            fastq['read_2'] = reads[1];
          }
          files.push(reads);
        }
      }
      return { 'files': files};
  }"
