class: CommandLineTool
cwlVersion: v1.2

doc: SORT command
label: sort
hints:
  - $import: ubuntu-docker.yml

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: file
    type: File
    inputBinding:
      position: 3
  - id: k
    type: string?
    inputBinding:
      position: 1
      prefix: '-k'
  - id: outFileName
    type: string
  - id: u
    type: boolean?
    inputBinding:
      position: 2
      prefix: '-u'
  - id: 'n'
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-n'
outputs:
  - id: output
    type: File
    outputBinding:
      glob: $(inputs.outFileName)

stdout: $(inputs.outFileName)

baseCommand: [sort]
