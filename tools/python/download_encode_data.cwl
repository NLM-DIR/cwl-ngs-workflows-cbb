class: CommandLineTool
cwlVersion: v1.2

label: Download Encode ChIP-Seq Data
doc: Download Encode ChIP-Seq Data

hints:
  DockerRequirement:
    dockerImageId: cwl-ngs-workflows-cbb-encode:3.12
    dockerFile: |
      FROM ubuntu:24.04
      ENV DEBIAN_FRONTEND="noninteractive"
      USER root
      ENV LC_ALL="C.UTF-8"
      ENV PATH="/root/.local/bin:$PATH"
      
      RUN apt-get update &&  apt-get install -y \
            dnsutils  \
            curl && \
          apt-get clean && apt-get purge && \
          rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*  && \
          curl -o /tmp/Miniconda3-latest-Linux-x86_64.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
          bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -f -p /usr/local/conda && \
          /usr/local/conda/bin/conda init && \
          /usr/local/conda/bin/conda tos accept --channel https://repo.anaconda.com/pkgs/main && \
          /usr/local/conda/bin/conda tos accept --channel https://repo.anaconda.com/pkgs/r && \
          /usr/local/conda/bin/conda update conda && \
          /usr/local/conda/bin/conda update --all && \
          /usr/local/conda/bin/conda config --add channels defaults && \
          /usr/local/conda/bin/conda config --add channels bioconda && \
          /usr/local/conda/bin/conda config --add channels conda-forge && \
          /usr/local/conda/bin/conda create -n py3.12 python=3.12 && \
          /usr/local/conda/bin/conda clean --all && \
          rm /tmp/Miniconda3-latest-Linux-x86_64.sh && \
          apt-get remove -y curl
      
      ENV PATH="/usr/local/conda/envs/py3.12/bin:${PATH}"
      RUN /usr/local/conda/envs/py3.12/bin/python -m pip install pandas==2.3.1 openpyxl==3.1.5 requests==2.32.4 tqdm==4.67.1

  SoftwareRequirement:
    packages:
      - package: 'pandas'
        version:
          - '2.3.1'
        specs:
          - https://anaconda.org/conda-forge/pandas
      - package: 'openpyxl'
        version:
          - '3.1.5'
        specs:
          - https://anaconda.org/conda-forge/openpyxl
      - package: 'requests'
        version:
          - '2.32.4'
        specs:
          - https://anaconda.org/conda-forge/requests
      - package: 'tqdm'
        version:
          - '4.67.1'
        specs:
          - https://anaconda.org/conda-forge/tqdm


requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: my.py
        entry: |
          import os
          import sys
          import json
          import pandas
          import requests
          from tqdm import tqdm

          base_url = "https://www.encodeproject.org"
          experiment = sys.argv[1]
          r1 = sys.argv[2]
          r2 = sys.argv[3]
          genome = sys.argv[4]
          
          def download_file(download_url, output_path):
              file_name = os.path.basename(output_path)
              print(f"Downloading {file_name}...")
              # Start the download with streaming
              with requests.get(download_url, stream=True) as r:
                  r.raise_for_status()
                  total_size = int(r.headers.get("Content-Length", 0))
                  block_size = 8192  # 8 KB
          
                  with open(output_path, "wb") as f, tqdm(
                      total=total_size,
                      unit="B",
                      unit_scale=True,
                      unit_divisor=1024,
                      desc=file_name,
                      initial=0,
                  ) as bar:
                      for chunk in r.iter_content(chunk_size=block_size):
                          if chunk:
                              f.write(chunk)
                              bar.update(len(chunk))
          
          def download_experiment_reads(data, experiment, r1, r2):
              r1_url = f"{base_url}/files/{r1}/@@download/{r1}.fastq.gz"
              file_name = f"{experiment}_1.fastq.gz"
              download_file(r1_url, file_name)
              r2_url = f"{base_url}/files/{r2}/@@download/{r2}.fastq.gz"
              file_name = f"{experiment}_2.fastq.gz"
              download_file(r2_url, file_name)
          
          def download_bed_narrowPeak(data, experiment, genome):
              for file_obj in data.get("files", []):
                  if file_obj.get("file_format") == "bed" and file_obj.get("assembly") == genome and \
                      file_obj.get("file_type") == 'bed narrowPeak' and file_obj.get('preferred_default') == True:
                      analyses = file_obj.get('analyses')
                      good = False
                      for a in analyses:
                          if str(a.get('pipeline_version')) == "1.5.1":
                              good = True
                              break
                      if good:
                          href = file_obj.get("href")
                          output_prefix = file_obj.get("output_type").replace(' ', '_')
                          file_name = f"{experiment}_{output_prefix}_narrowPeak.bed.gz"
                          download_file(f"{base_url}{href}", file_name)
          
          api_url = f"{base_url}/experiments/{experiment}/?format=json"
          response = requests.get(api_url, headers={"Accept": "application/json"})
          response.raise_for_status()
          data = response.json()
          download_experiment_reads(data, experiment, r1, r2)
          download_bed_narrowPeak(data, experiment, genome)

inputs:
  - id: experiment
    type: string
    inputBinding:
      position: 1
  - id: r1
    type: string
    inputBinding:
      position: 2
  - id: r2
    type: string
    inputBinding:
      position: 3
  - id: genome
    type: string
    inputBinding:
      position: 4
outputs:
  - id: output
    type: File[]
    outputBinding:
      glob: $(inputs.experiment)*

baseCommand: ["python","my.py"]
