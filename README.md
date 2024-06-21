[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.11396812.svg)](https://doi.org/10.5281/zenodo.11396812)
# Fasta_GFF3_Equalizer_Bash
![alt text](https://github.com/raramayo/Fasta_GFF3_Equalizer_Bash/blob/main/Images/Fasta_GFF3_Equalizer_Logo.png)

## Motivation

The main motivation for creating this script was to be able
to pre-process both transcriptome and proteome FASTA files before
subjecting them to computational analysis.

This script was developed because transcriptome and protein files
downloaded from the ENSEMBL database contain transcripts and protein
sequences corresponding to 'patched' and/or 'alternate' regions of the
human genome that are not part of the 'Standard Reference' genome. In
addition, these sequences are not declared in the GFF3 file
corresponding to the standard reference genome. The presence of these
'extra' sequences can therefore potentially confound downstream
analyses, such as transcriptome profiling and evolutionary proteomic
comparisons.

In addition to identifying and separating sequences not declared in
the GFF3 file, from those who are, The script splits the sequences
present in the provided FASTA file into separate files according to
their associated annotated BioTypes. Each resulting file will thus
contain sequences corresponding to the same BioType. Additionally,
transcripts and protein sequences not declared in the GFF3 file are
printed in a separate file.

Furthermore, the script generates a transcript-to-gene relationship
table for use in transcriptional profiling experiments.

This script was developed for and tested with NCBI, ENSEMBL, and
GENCODE GFF3 *Homo sapiens* files. It has not been tested with other
GFF3 files. While the script is expected to work well with NCBI GFF3
files for other organisms, it can be easily modified to work with
ENSEMBL and GENCODE GFF3 files from other organisms (e.g., *Mus
musculus*).

## Documentation

```
###########################################################################
ARAMAYO_LAB

Copyright (C) 2024 Rodolfo Aramayo

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>.

SCRIPT_NAME:                    Fasta_GFF3_Equalizer_v1.0.2.sh
SCRIPT_VERSION:                 1.0.2

USAGE: Fasta_GFF3_Equalizer_v1.0.2.sh
 -f Fasta_File.fa               # REQUIRED Fasta Format Transcripts or
                                           Fasta Format  Proteins File
 -g GFF3_Genome_File.gff3       # REQUIRED
 -x Number of Cores             # OPTIONAL (default = 2)
 -z TMPDIR Location             # OPTIONAL (default=0='TMPDIR Run')

TYPICAL COMMANDS:
 Fasta_GFF3_Equalizer_v1.0.2.sh -f Fasta_Transcripts_File.fa -g GFF3_Genome_File.gff3
 Fasta_GFF3_Equalizer_v1.0.2.sh -f Fasta_Proteins_File.fa -g GFF3_Genome_File.gff3

INPUT01:          -f FLAG       REQUIRED
INPUT01_FORMAT:                 Fasta Format File
INPUT01_DEFAULT:                No default

INPUT02:          -g FLAG       REQUIRED input
INPUT02_FORMAT:                 GFF3 Format File
INPUT02_DEFAULT:                No default

INPUT03:          -x FLAG       OPTIONAL input
INPUT03_FORMAT:                 Numeric
INPUT03_DEFAULT:                4
INPUT03_NOTES:
 The maximum number of cores requested should be equal to N-1; where N is
the total number of cores available in the computer performing the analysis.

INPUT04:          -z FLAG       OPTIONAL input
INPUT04_FORMAT:                 Numeric: '0' == TMPDIR Run | '1' == Local Run
INPUT04_DEFAULT:                '0' == TMPDIR Run
INPUT04_NOTES:
 '0' Processes the data in the $TMPDIR directory of the computer used or of
the node assigned by the SuperComputer scheduler.

 Processing the data in the $TMPDIR directory of the node assigned by the
SuperComputer scheduler reduces the possibility of file error generation
due to network traffic,

 '1' Processes the data in the same directory where the script is being run.

DEPENDENCIES:
 GNU AWK:       Required (https://www.gnu.org/software/gawk/)
 GNU COREUTILS: Required (https://www.gnu.org/software/coreutils/)
 GNU Parallel:  Required (https://www.gnu.org/software/parallel/)
 faSomeRecords: Required (https://hgdownload.soe.ucsc.edu/admin/exe/)

Author:                            Rodolfo Aramayo
WORK_EMAIL:                        raramayo@tamu.edu
PERSONAL_EMAIL:                    rodolfo@aramayo.org

Repository: https://github.com/raramayo/Fasta_GFF3_Equalizer_Bash
Issues:     https://github.com/raramayo/Fasta_GFF3_Equalizer_Bash/issues
###########################################################################
```

## Development/Testing Environment:

```
Distributor ID:       Apple, Inc.
Description:          Apple M1 Max
Release:              14.4.1
Codename:             Sonoma
```

```
Distributor ID:       Ubuntu
Description:          Ubuntu 22.04.3 LTS
Release:              22.04
Codename:             jammy
```

## Required Script Dependencies:
### GNU AWK (https://www.gnu.org/software/gawk/)
#### Version Number: 5.3.0, API 4.0

```
GNU Awk 5.3.0, API 4.0
Copyright (C) 1989, 1991-2023 Free Software Foundation.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.
```

### GNU COREUTILS (https://www.gnu.org/software/coreutils/)
#### Version Number: 8.30

```
(GNU coreutils) 9.4
Copyright (C) 2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Richard M. Stallman and David MacKenzie.
```

### GNU Parallel (https://www.gnu.org/software/parallel/)
#### Version Number: 20240422

```
GNU parallel 20240422
Copyright (C) 2007-2024 Ole Tange, http://ole.tange.dk and Free Software
Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
GNU parallel comes with no warranty.

Web site: https://www.gnu.org/software/parallel

When using programs that use GNU Parallel to process data for publication
please cite as described in 'parallel --citation'.
```

### kentUtils (faSomeRecords) (http://hgdownload.soe.ucsc.edu/admin/exe/)
#### Version Number: 2024-05-21
