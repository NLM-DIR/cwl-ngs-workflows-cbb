cwlVersion: v1.2
class: ExpressionTool

label: tsvcolumn2list
doc: Read a TSV table in a file and one column in a list

requirements:
  InlineJavascriptRequirement: {}

hints:
  - $import: ubuntu-docker.yml

inputs:
  table:
    type: File
    inputBinding:
      loadContents: true
  column_name:
    type: string

outputs:
  rows:
    type: string[]

expression:
  "${
     var lines = inputs.table.contents.split('\\n');
     var header = lines[0].split('\\t');
     var colIndex = -1;
     var rows = [];
     for (var i = 0; i < header.length; i++) {
        if (header[i] == inputs.column_name){
           colIndex = i;
           break;
        }
     }
     if (colIndex !== -1){
        for (var i = 1; i < lines.length; i++) {
           var col = lines[i].split('\\t')[colIndex];
           if (col != undefined && col.length != 0){
              rows.push(col)
           }
        }
     }
     return { 'rows': rows } ;
  }"
