#!/usr/bin/env bash

func_copyright ()
{
    cat <<COPYRIGHT

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

COPYRIGHT
};

func_authors ()
{
    cat <<AUTHORS
Author:                            Rodolfo Aramayo
WORK_EMAIL:                        raramayo@tamu.edu
PERSONAL_EMAIL:                    rodolfo@aramayo.org
AUTHORS
};

func_usage()
{
    cat <<EOF
###########################################################################
ARAMAYO_LAB
$(func_copyright)

SCRIPT_NAME:                    $(basename ${0})
SCRIPT_VERSION:                 ${version}

USAGE: $(basename ${0})
 -f Fasta_File.fa               # REQUIRED Fasta Format Transcripts or
                                           Fasta Format  Proteins File
 -g GFF3_Genome_File.gff3       # REQUIRED
 -x Number of Cores             # OPTIONAL (default = 2)
 -z TMPDIR Location             # OPTIONAL (default=0='TMPDIR Run')

TYPICAL COMMANDS:
 $(basename ${0}) -f Fasta_Transcripts_File.fa -g GFF3_Genome_File.gff3
 $(basename ${0}) -f Fasta_Proteins_File.fa -g GFF3_Genome_File.gff3

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
 '0' Processes the data in the \$TMPDIR directory of the computer used or of
the node assigned by the SuperComputer scheduler.

 Processing the data in the \$TMPDIR directory of the node assigned by the
SuperComputer scheduler reduces the possibility of file error generation
due to network traffic,

 '1' Processes the data in the same directory where the script is being run.

DEPENDENCIES:
 GNU AWK:       Required (https://www.gnu.org/software/gawk/)
 GNU COREUTILS: Required (https://www.gnu.org/software/coreutils/)
 GNU Parallel:  Required (https://www.gnu.org/software/parallel/)
 faSomeRecords: Required (https://hgdownload.soe.ucsc.edu/admin/exe/)

$(func_authors)

Repository: https://github.com/raramayo/Fasta_GFF3_Equalizer_Bash
Issues:     https://github.com/raramayo/Fasta_GFF3_Equalizer_Bash/issues
###########################################################################
EOF
};

## Defining_Script_Current_Version
version="1.0.2";

## Defining_Script_Initial_Version_Data (date '+DATE:%Y/%m/%d')
version_date_initial="DATE:2022/12/22";

## Defining_Script_Current_Version_Data (date '+DATE:%Y/%m/%d')
version_date_current="DATE:2024/06/21";

## Testing_Script_Input
## Is_the number_of_arguments null?
if [[ ${#} -eq 0 ]];then
    echo -e "\nPlease enter required arguments";
    func_usage;
    exit 1;
fi

while true;do
    case ${1} in
        -h|--h|-help|--help|-\?|--\?)
            func_usage;
            exit 0;
            ;;
        -v|--v|-version|--version)
            printf "Version: $version %s\n" >&2;
            exit 0;
            ;;
        -f|--f|-fasta|--fasta)
            fastafile=${2};
            shift;
            ;;
        -g|--g|-gff|--gff|-gff3|--gff3)
            gff=${2};
            shift;
            ;;
        -x|--x|-xcores|--xcores)
            ncores=${2};
            shift;
            ;;
	-z|--z|-tmp-dir|--tmp-dir)
            tmp_dir=${2};
            shift;
            ;;
        -?*)
            printf '\nWARNNING: Unknown Option (ignored): %s\n\n' ${1} >&2;
            func_usage;
            exit 0;
            ;;
        :)
            printf '\nWARNING: Invalid Option (ignored): %s\n\n' ${1} >&2;
            func_usage;
            exit 0;
            ;;
        \?)
            printf '\nWARNING: Invalid Option (ignored): %s\n\n' ${1} >&2;
            func_usage;
            exit 0;
            ;;
        *)  # Should not get here
            break;
            exit 1;
            ;;
    esac
    shift;
done

## Processing: -f Flag
if [[ -z ${fastafile} ]];then
    echo "Please provide a name for a transcriptome or proteome file in fasta format";
    func_usage;
    exit 1;
fi
if [[ ! -f ${fastafile} ]];then
    echo "Please provide a transcriptome or proteome file in fasta format";
    func_usage;
    exit 1;
fi

## Processing: -g Flag
if [[ -z ${gff} ]];then
    echo "Please provide a name for a file in gff3 format";
    func_usage;
    exit 1;
fi
if [[ ! -f ${gff} ]];then
    echo "Please provide a file in gff3 format";
    func_usage;
    exit 1;
fi

## Processing: -x Flag
## Assigning_Number_of_Cores
if [[ -z ${ncores} ]];then
    ncores=${ncores:=4};
fi
## Checking_Processors_Number
var_nproc=$(nproc --all);
if [[ ${ncores} -ge ${var_nproc} ]];then
    ncores=$(( ${var_nproc} - 2 ));
elif [[ ${ncores} -eq ${var_nproc} ]];then
    ncores=$(( "$NPROC" - 2 ));
else [[ ${ncores} -lt ${var_nproc} ]];
fi

## Processing '-z' Flag
## Determining_Where_The_TMPDIR_Will_Be_Generated
if [[ -z ${tmp_dir} ]];then
    tmp_dir=${tmp_dir:=0};
fi

var_regex="^[0-1]+$"
if ! [[ ${tmp_dir} =~ ${var_regex} ]];then
    echo "Please provide a valid number (e.g., 0 or 1), for this variable";
    func_usage;
    exit 1;
fi

## Generating_Directories
var_script_out_data_dir=""$(pwd)"/"${fastafile%.*}"_Fasta_GFF3_Equalizer.dir";
export var_script_out_data_dir=""$(pwd)"/"${fastafile%.*}"_Fasta_GFF3_Equalizer.dir";

if [[ ! -d ${var_script_out_data_dir} ]];then
    mkdir ${var_script_out_data_dir};
else
    rm ${var_script_out_data_dir}/* &>/dev/null;
fi

if [[ -d ${fastafile%.*}_Fasta_GFF3_Equalizer.tmp ]];then
    rm -fr ${fastafile%.*}_Fasta_GFF3_Equalizer.tmp &>/dev/null;
fi

## Generating/Cleaning_TMP_Data_Directory
if [[ ${tmp_dir} -eq 0 ]]; then
    ## Defining Script TMP Data Directory
    var_script_tmp_data_dir="$(pwd)/${INFILE01%.fa}_Fasta_GFF3_Equalizer.tmp";
    export var_script_tmp_data_dir;

    if [[ -d ${var_script_tmp_data_dir} ]];then
        rm -fr ${var_script_tmp_data_dir};
    fi

    if [[ -z ${TMPDIR} ]];then
        TMPDIR=$(mktemp -d -t tmp.XXXXXX);
    fi

    TMP=$(mktemp -d -p ${TMPDIR} tmp.XXXXXX);
    var_script_tmp_data_dir=${TMP};
    export var_script_tmp_data_dir;
fi

if [[ ${tmp_dir} -eq 1 ]];then
    ## Defining Script TMP Data Directory
    var_script_tmp_data_dir=""$(pwd)"/"${fastafile%.*}"_Fasta_GFF3_Equalizer.tmp";
    export var_script_tmp_data_dir=""$(pwd)"/"${fastafile%.*}"_Fasta_GFF3_Equalizer.tmp";

    if [[ ! -d ${var_script_tmp_data_dir} ]];then
        mkdir ${var_script_tmp_data_dir};
    else
        rm -fr ${var_script_tmp_data_dir};
        mkdir ${var_script_tmp_data_dir};
    fi
fi

## Initializing_Log_File
time_execution_start=$(date +%s)
echo -e "Starting Processing Genome: "${fastafile%.*}" on: "$(date)"" > ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

## Verifying_Dependency_Existence
echo -e "Verifying Software Dependency Existence on: "$(date)"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
## Determining_Current_Computer_Platform
osname=$(uname -s);
cputype=$(uname -m);
case "${osname}"-"${cputype}" in
    Linux-x86_64 )           plt=Linux ;;
    Darwin-x86_64 )          plt=Darwin ;;
    Darwin-*arm* )           plt=Silicon ;;
    CYGWIN_NT-* | MINGW*-* ) plt=CYGWIN_NT ;;
    Linux-*arm* )            plt=ARM ;;
esac
## Determining_GNU_Bash_Version
if [[ ${BASH_VERSINFO:-0} -ge 4 ]];then
    echo -e "GNU_BASH version "${BASH_VERSINFO}" is Installed" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
else
    echo "GNU_BASH version 4 or higher is Not Installed";
    echo "Please Install GNU_BASH version 4 or higher";
    rm -fr ${var_script_out_data_dir};
    rm -fr ${var_script_tmp_data_dir};
    func_usage;
    exit 1;
fi
## Testing_GNU_Awk_Installation
type gawk &> /dev/null;
var_sde=$(echo ${?});
if [[ ${var_sde} -eq 0 ]];then
    echo "GNU_AWK is Installed" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
else
    echo "GNU_AWK is Not Installed";
    echo "Please Install GNU_AWK";
    rm -fr ${var_script_out_data_dir};
    rm -fr ${var_script_tmp_data_dir};
    func_usage;
    exit 1;
fi
## Testing_faSomeRecords_Installation
type faSomeRecords &> /dev/null;
var_sde="$(echo ${?})"
if [[ $var_sde -eq 0 ]];then
    echo "faSomeRecords is Installed" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
else
    echo "faSomeRecords is Not Installed";
    echo "Please Install faSomeRecords";
    rm -fr ${var_script_out_data_dir};
    rm -fr ${var_script_tmp_data_dir};
    func_usage;
    exit 1;
fi
## Testing_Parallel_Installation
type parallel &> /dev/null;
var_sde=$(echo ${?});
if [[ ${var_sde} -eq 0 ]];then
    echo "PARALLEL is Installed" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
else
    echo "PARALLEL is Not Installed";
    echo "Please Install PARALLEL";
    rm -fr ${var_script_out_data_dir};
    rm -fr ${var_script_tmp_data_dir};
    func_usage;
    exit 1;
fi

echo -e "Software Dependencies Verified on: "$(date)"\n" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "Script Running on: "${osname}", "${cputype}"\n" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

## set LC_ALL to "C"
export LC_ALL="C";

echo -e "Command Issued Was:" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "\tFasta File Analyzed:\t\t\t"${fastafile}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "\tGFF3 File Analyzed:\t\t\t"${gff}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -ne "\tCommand:\t\t\t\t" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -ne ""$(basename ${0})"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -ne " -f "${fastafile}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -ne " -g "${gff}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -ne " -x "${ncores}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e " -z "${tmp_dir}"" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

## Starting_Script
## Determining if the fasta file contains nucleotide or protein sequences
grep -iqz '[EFILPQZX]' <(grep -v '^>' ${fastafile} | head -n 1000 | sed 's/[ACGTUNacgtun]//g') && var_fasta_file_type="proteins" || var_fasta_file_type="nucleotides";

## Compiling_the_gene_information_present_in_the_GFF_file
#_001_File_
grep -Pvi \
     "^#|\texon\t|\tmatch\t|\tcDNA_match\t|Genomic\t|\tbiological_region\t|\tenhancer\t|\ttranscriptional_cis_regulatory_region\t|\tprotein_binding_site\t|\tnucleotide_motif\t|\tnon_allelic_homologous_recombination_region\t|\tpromoter\t|\tmeiotic_recombination_region\t|\tregion\t|\tmobile_genetic_element\t|\tDNaseI_hypersensitive_site\t|\tconserved_region\t|\tsilencer\t|\tCAGE_cluster\t|\torigin_of_replication\t|\ttandem_repeat\t|\trepeat_instability_region\t|\tmitotic_recombination_region\t|\tenhancer_blocking_element\t|\tTATA_box\t|\tsequence_alteration\t|\tresponse_element\t|\tlocus_control_region\t|\trecombination_feature\t|\tGC_rich_promoter_region\t|\tmatrix_attachment_site\t|\tsequence_secondary_structure\t|\tepigenetically_modified_region\t|\treplication_regulatory_region\t|\tdirect_repeat\t|\tminisatellite\t|\tinsulator\t|\tchromosome_breakpoint\t|\trepeat_region\t|\tmicrosatellite\t|\tdispersed_repeat\t|\tCAAT_signal\t|\tnucleotide_cleavage_site\t|\tsequence_feature\t|\treplication_start_site\t|\tsequence_comparison\t|\tregulatory_region\t|\timprinting_control_region\t|\tD_loop\t|\tV_gene_segment\t|\tinverted_repeat\t|\tfive_prime_UTR\t|\tthree_prime_UTR\t|\tscaffold\t|\tJ_gene_segment\t|\tD_gene_segment\t|\tC_gene_segment\t|\tchromosome\t|\tstart_codon|\tstop_codon\t|\tstop_codon_redefined_as_selenocysteine\t|\texon\t|\tgene\t" \
     ${gff} \
     > ${var_script_tmp_data_dir}/001_Clean_GFF3.txt;

## Extract_unique_identifiers_from_the ${var_script_tmp_data_dir}/001_Clean_GFF3.txt, excluding headers
unique_ids=$(awk '{print $1}' "${var_script_tmp_data_dir}/001_Clean_GFF3.txt" | awk -F '_' '{print $1}' | sort --parallel=${ncores} | uniq)

## Define_the_unique_identifiers_for_each_GFF3_file_type
ncbi_ids="NC NT NW"
ensembl_ids1="1 10 11 12 13 14 15 16 17 18 19 2 20 21 22 3 4 5 6 7 8 9 GL000009.2 GL000194.1 GL000195.1 GL000205.2 GL000213.1 GL000216.2 GL000218.1 GL000219.1 GL000220.1 GL000225.1 KI270442.1 KI270711.1 KI270713.1 KI270721.1 KI270726.1 KI270727.1 KI270728.1 KI270731.1 KI270733.1 KI270734.1 KI270744.1 KI270750.1 MT X Y"
ensembl_ids2="1 10 11 12 13 14 15 16 17 18 19 2 20 21 22 3 4 5 6 7 8 9 MT X Y"
gencode_ids="chr1 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr2 chr20 chr21 chr22 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chrM chrX chrY"

## Function_to_check_if_a_GFF3_file's_unique_identifiers_match_a_given_set
matches_ids() {
    local ids="$1"
    local key_ids="$2"
    local match_count=0
    local total_keys=$(echo "$key_ids" | wc -w)

    for key in $key_ids;do
        if echo "$ids" | grep -qw "$key";then
            match_count=$((match_count + 1))
        fi
    done

    ## Consider_it_a_match_if_more_than_half_of_the_key_identifiers_are_found
    if [ "$match_count" -ge $((total_keys / 2)) ];then
        return 0
    else
        return 1
    fi
}

## Identify_the_GFF3_file_type_based_on_the_presence_of_key_identifiers
if matches_ids "$unique_ids" "$ncbi_ids";then
    var_gff3_file_type="NCBI";
elif matches_ids "$unique_ids" "$ensembl_ids1";then
    var_gff3_file_type="ENSEMBL";
elif matches_ids "$unique_ids" "$ensembl_ids2";then
    var_gff3_file_type="ENSEMBL";
elif matches_ids "$unique_ids" "$gencode_ids";then
    var_gff3_file_type="GENCODE";
else
    echo "The GFF3 file does not match any known set"
    echo "Please provide either an NCBI, ENSEMBL, or a GENCODE GFF3 File format";
    echo "Alternatively, please report this behavior";
    func_usage;
    exit 1
fi

#_002_File_
#_003_File_
## Extracting_sequences_Headers_from_the_Fasta_file
## Extracting_sequences_IDs_from_the_Fasta_file
if [[ ${var_gff3_file_type} == NCBI ]];then
    grep ">" ${fastafile} | \
	sed 's/^>//' | \
	tee ${var_script_tmp_data_dir}/002_Fasta_Headers.txt | \
	awk '{print $1}' | \
	sed 's/\.[0-9]*//g' \
	    > ${var_script_tmp_data_dir}/003_Fasta_Headers.txt;
elif [[ ${var_gff3_file_type} == ENSEMBL ]];then
    grep ">" ${fastafile} | \
	sed 's/^>//' | \
	tee ${var_script_tmp_data_dir}/002_Fasta_Headers.txt | \
	awk '{print $1}' | \
	sed 's/\.[0-9]*//g' \
	    > ${var_script_tmp_data_dir}/003_Fasta_Headers.txt;
elif [[ ${var_gff3_file_type} == GENCODE ]];then
    grep ">" ${fastafile} | \
	sed 's/^>//' | \
	tee ${var_script_tmp_data_dir}/002_Fasta_Headers.txt | \
	awk -F '|' '{print $1}' | \
	sed 's/\.[0-9]*//g' \
	    > ${var_script_tmp_data_dir}/003_Fasta_Headers.txt;
fi
#_004t_File_ and #_004p_File_
#_005t_File_ and #_005p_File_
#_006t_File_ and #_006p_File_
#_007t_File_ and #_007p_File_
if [[ ${var_gff3_file_type} == NCBI ]];then
    if [[ ${var_fasta_file_type} == nucleotides ]];then
	#_004t_File_
	grep -P ";Parent=gene-" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/ID=rna-//;s/Parent=gene-//;s/Parent=rna-//' \
		> ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt;
	#_005t_File_
	awk '{print $1}' \
	    ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_006t_File_
	while read r;do
	    grep -P "^${r}\t" \
		 ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
		awk -F ';' '{print $1 "\t" $2}' \
		    >> ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_007t_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt;
    elif [[ ${var_fasta_file_type} == proteins ]];then
	#_004p_File_
	grep -P "\tID=cds-" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/ID=cds-//;s/Parent=rna-//' \
		> ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt;
	awk '{print $1}' \
	    ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_006p_File_
	while read r;do
	    grep -P "^${r}\t" \
		 ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
		awk '{print $1 "\t" $2}' | \
		awk -F ';' '{print $1 "\t" $2}' \
		    >> ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_007p_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt;
    fi
elif [[ ${var_gff3_file_type} == ENSEMBL ]];then
    if [[ ${var_fasta_file_type} == nucleotides ]];then
	#_004t_File_
	grep -P "\tID=transcript:" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/ID=transcript://;s/Parent=gene://' \
		> ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt;
	awk '{print $1}' \
	    ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_006t_File_
	while read r;do
	    grep -P "^${r}\t" \
		 ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
		awk '{print $1 "\t" $2}' | \
		awk -F ';' '{print $1 "\t" $2}' \
		    >> ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_007t_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt;
    elif [[ ${var_fasta_file_type} == proteins ]];then
	#_004p_File_
	grep -P "\tID=CDS:" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/ID=CDS://;s/Parent=transcript://' \
		> ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt;
	#_005p_File_
	awk '{print $1}' \
	    ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_006p_File_
	while read r;do
	    grep -P "^${r}\t" \
		 ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
		awk '{print $1 "\t" $2}' | \
		awk -F ';' '{print $1 "\t" $2}' \
		    >> ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_007p_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt;
    fi
elif [[ ${var_gff3_file_type} == GENCODE ]];then
    if [[ ${var_fasta_file_type} == nucleotides ]];then
	#_004t_File_
	grep -P "\tID=ENST" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/ID=//;s/Parent=//;s/gene_name=//;s/protein_id=//;s/transcript_type=//' \
		> ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt;
	#_005t_File_
	awk '{print $2}' \
	    ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
	    awk -F ';' '{print $7}' | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_006t_File_
	while read r;do
	    grep -P "${r}" \
		 ${var_script_tmp_data_dir}/004t_GFF3_f3_f9.txt | \
		awk '{print $1 "\t" $2}' | \
		awk -F ';' '{print $1 "\t" $2 "\t" $6 "\t" $7 "\t" $10}' | \
		awk '{print $5 "\t" $2 "\t" $3 "\t" $4}' \
		    >> ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
	#_007t_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006t_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt;
    elif [[ ${var_fasta_file_type} == proteins ]];then
	#_004p_File_
	grep -P "\tID=CDS:" \
	     ${var_script_tmp_data_dir}/001_Clean_GFF3.txt | \
	    awk '{print $3 "\t" $9}' | \
	    sort --parallel=${ncores} | \
	    uniq | \
	    sed 's/Parent=//;s/protein_id=//;s/ID=CDS://;s/gene_name=//;s/exon_id=//;s/transcript_type=//' \
		> ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt;
	#_005p_File_
	awk '{print $2}' \
	    ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
	    awk -F ';' '{print $7}' | \
	    sort --parallel=${ncores} | \
	    uniq \
		> ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_006p_File_
	while read r;do
	    grep -P "${r}" \
		 ${var_script_tmp_data_dir}/004p_GFF3_f3_f9.txt | \
		awk '{print $1 "\t" $2}' | \
		awk -F ';' '{print $7 "\t" $12 "\t" $2 "\t" $6 "\t" $1}' | \
		awk '{print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5}' \
		    >> ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt;
	done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
	#_007p_File_
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/006p_Transcripts_IDs.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt;
    fi
fi

#_008_File_
#_009_File_
#_010_File_
#_011_File_
if [[ ${var_fasta_file_type} == nucleotides ]];then
    #_008_File_
    while read r;do
	grep -P "^${r}\t" \
	     ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt | \
	    awk '{print $1 "\t" $2}' \
		>> ${var_script_tmp_data_dir}/008_Transcripts_IDs_${r}.txt;
    done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
    #_009_File_
    while read r;do
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/008_Transcripts_IDs_${r}.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/009_Transcripts_IDs_${r}.txt;
    done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
    #_010_File_
    #_011_File_
    while read r;do
	awk '{print $2}' \
	    ${var_script_tmp_data_dir}/009_Transcripts_IDs_${r}.txt \
	    >> ${var_script_tmp_data_dir}/010_Transcripts_IDs_${r}_f1.txt;
	echo -e "010_Transcripts_IDs_"${r}"_f1.txt" \
	     >> ${var_script_tmp_data_dir}/011_All_Transcripts_IDs.txt;
    done < ${var_script_tmp_data_dir}/005t_GFF3_f3.txt;
elif [[ ${var_fasta_file_type} == proteins ]];then
    #_008_File_
    while read r;do
	grep -P "${r}" \
	     ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt | \
	    awk '{print $1 "\t" $2}' \
		>> ${var_script_tmp_data_dir}/008_Transcripts_IDs_${r}.txt;
    done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
    #_009_File_
    while read r;do
	sort --parallel=${ncores} \
	     ${var_script_tmp_data_dir}/008_Transcripts_IDs_${r}.txt | \
	    uniq \
		>> ${var_script_tmp_data_dir}/009_Transcripts_IDs_${r}.txt;
    done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
    #_010_File_
    #_011_File_
    while read r;do
	awk '{print $2}' \
	    ${var_script_tmp_data_dir}/009_Transcripts_IDs_${r}.txt \
	    >> ${var_script_tmp_data_dir}/010_Transcripts_IDs_${r}_f1.txt;
	echo -e "010_Transcripts_IDs_"${r}"_f1.txt" \
	     >> ${var_script_tmp_data_dir}/011_All_Transcripts_IDs.txt;
    done < ${var_script_tmp_data_dir}/005p_GFF3_f3.txt;
fi

#_012_File_
#_013_File_
#_014_File_
while read r;do
    local_var_01=${r#*Transcripts_IDs_};
    local_var_01=${local_var_01%_f1.txt};
    #_012_File_
    printf "grep -f "${var_script_tmp_data_dir}"/"${r}" "${var_script_tmp_data_dir}"/002_Fasta_Headers.txt >> "${var_script_tmp_data_dir}"/014_Fasta_Headers_"${local_var_01}".txt\n" \
	   >> ${var_script_tmp_data_dir}/012_Fasta_Headers_${local_var_01}_commands;
    #_013_File_
    printf "bash "${var_script_tmp_data_dir}"/012_Fasta_Headers_"${local_var_01}"_commands\n" >> ${var_script_tmp_data_dir}/013_Fasta_Headers_main_commands;
done < ${var_script_tmp_data_dir}/011_All_Transcripts_IDs.txt;

#_014_File_
parallel -j ${ncores} < ${var_script_tmp_data_dir}/013_Fasta_Headers_main_commands;

## Wait_For_All_PIDs_To_Finish
for job in $(jobs -p);
do
    wait ${job};
done

#_015_File_
while read r;do
    local_var_01=${r#*Transcripts_IDs_};
    local_var_01=${local_var_01%_f1.txt};
    #_015_File_
    faSomeRecords \
	${fastafile} \
	${var_script_tmp_data_dir}/014_Fasta_Headers_${local_var_01}.txt \
	${var_script_tmp_data_dir}/015_${local_var_01}_Sequences.fa;
done < ${var_script_tmp_data_dir}/011_All_Transcripts_IDs.txt;

while read r;do
    local_var_01=${r#*Transcripts_IDs_};
    local_var_01=${local_var_01%_f1.txt};
    #_015_File_Empty Files Removal
    if [[ -s ${var_script_tmp_data_dir}/015_${local_var_01}_Sequences.fa ]];then
	cp ${var_script_tmp_data_dir}/015_${local_var_01}_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_${local_var_01}_Sequences.fa;
    fi
done < ${var_script_tmp_data_dir}/011_All_Transcripts_IDs.txt;

#_016_File_
#_017_File_
if [[ ${var_fasta_file_type} == nucleotides ]];then
    #_016_File_
    awk '{print $2}' \
	${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt \
	> ${var_script_tmp_data_dir}/016_IDs_Included_GFF3_File.txt;
    #_017_File_
    grep -f  ${var_script_tmp_data_dir}/016_IDs_Included_GFF3_File.txt \
	 ${var_script_tmp_data_dir}/002_Fasta_Headers.txt | \
	sort --parallel=${ncores} | \
	uniq \
	    > ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt;
elif [[ ${var_fasta_file_type} == proteins ]];then
    #_016_File_
    awk '{print $2}' \
	${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt \
	> ${var_script_tmp_data_dir}/016_IDs_Included_GFF3_File.txt;
    #_017_File_
    grep -f  ${var_script_tmp_data_dir}/016_IDs_Included_GFF3_File.txt \
	 ${var_script_tmp_data_dir}/002_Fasta_Headers.txt | \
	sort --parallel=${ncores} | \
	uniq \
	    > ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt;
fi

#_018_File_
faSomeRecords \
    ${fastafile} \
    ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt \
    ${var_script_tmp_data_dir}/018_Sequences_Included_GFF3_File.fa;
if [[ -s ${var_script_tmp_data_dir}/018_Sequences_Included_GFF3_File.fa ]];then
    cp ${var_script_tmp_data_dir}/018_Sequences_Included_GFF3_File.fa ${var_script_out_data_dir}/01A_${fastafile%.*}_Sequences_Included_GFF3_File.fa;
fi
if [[ -s ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt ]];then
    cp ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt ${var_script_out_data_dir}/01A_${fastafile%.*}_Headers_Sequences_Included_GFF3_File.txt;
fi

if [[ $(grep -c ">" ${fastafile}) -ne $(wc -l <${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt) ]];then
    #_019_File_
    faSomeRecords -exclude \
		  ${fastafile} \
		  ${var_script_tmp_data_dir}/017_Headers_Sequences_Included_GFF3_File.txt \
		  ${var_script_tmp_data_dir}/019_Sequences_Excluded_GFF3_File.fa;
    #_020_File_
    ## Extracting_sequences_Headers_from_the_Fasta_file
    if [[ -s ${var_script_tmp_data_dir}/019_Sequences_Excluded_GFF3_File.fa ]];then
	cp ${var_script_tmp_data_dir}/019_Sequences_Excluded_GFF3_File.fa ${var_script_out_data_dir}/01B_${fastafile%.*}_Sequences_Excluded_GFF3_File.fa;
	grep ">" ${var_script_tmp_data_dir}/019_Sequences_Excluded_GFF3_File.fa | \
	    sed 's/^>//' \
		> ${var_script_tmp_data_dir}/020_Headers_Sequences_Excluded_GFF3_File.txt;
	cp ${var_script_tmp_data_dir}/020_Headers_Sequences_Excluded_GFF3_File.txt ${var_script_out_data_dir}/01B_${fastafile%.*}_Headers_Sequences_Excluded_GFF3_File.txt;
    fi
fi

## Printing_Transcripts_to_Genes_Tables_(t2g_Tables)
if [[ ${var_fasta_file_type} == nucleotides ]];then
    if [[ -s ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt ]];then
	echo -e "Transcript_BioType\tTranscript_ID\tGene_ID" \
	     > ${var_script_out_data_dir}/03A_${gff}_t2g_Table.txt;
	cat ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt | \
	    awk '{print $1 "\t" $2 "\t" $3}' \
		>> ${var_script_out_data_dir}/03A_${gff}_t2g_Table.txt;

	echo -e "Transcript_ID\tGene_ID" \
	     > ${var_script_out_data_dir}/03B_${gff}_t2g_Table.txt;
	awk '{print $2 "\t" $3}' \
	    ${var_script_tmp_data_dir}/007t_Transcripts_IDs.txt \
	    >> ${var_script_out_data_dir}/03B_${gff}_t2g_Table.txt;
    fi
elif [[ ${var_fasta_file_type} == proteins ]];then
    if [[ -s ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt ]];then
	echo -e "Transcript_BioType\tProtein_ID\tTranscript_ID" \
	     > ${var_script_out_data_dir}/03A_${gff}_t2g_Table.txt;
	cat ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt | \
	    awk '{print $1 "\t" $2 "\t" $3}' \
		>> ${var_script_out_data_dir}/03A_${gff}_t2g_Table.txt;

	echo -e "Protein_ID\tTranscript_ID" \
	     > ${var_script_out_data_dir}/03B_${gff}_t2g_Table.txt;
	awk '{print $2 "\t" $3}' \
	    ${var_script_tmp_data_dir}/007p_Transcripts_IDs.txt \
	    >> ${var_script_out_data_dir}/03B_${gff}_t2g_Table.txt;
    fi
fi

#_File_Renaming_
if [[ ${var_fasta_file_type} == "nucleotides" ]];then
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_transcript_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_transcript_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_non-coding_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_primary_transcript_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_primary_transcript_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_micro_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_snoRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_snoRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_small_nucleolar_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_snRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_snRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_small_nuclear_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_ncRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_ncRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_small_Cajal_body-specific_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_rRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_rRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_ribosomal_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_scRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_scRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_small_cytoplasmic_RNA_Sequences.fa;
    fi
    if [[ -s ${var_script_out_data_dir}/02_${fastafile%.*}_tRNA_Sequences.fa ]];then
	mv ${var_script_out_data_dir}/02_${fastafile%.*}_tRNA_Sequences.fa ${var_script_out_data_dir}/02_${fastafile%.*}_tRNA_Related_Sequences.fa;
    fi
fi

echo -e "\nResults:\n\tNo_Sequences\t\t\t\tFasta File" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

grep -Hc ">" ${fastafile} | \
    awk -F':' '{print "\t" $2 "\t\t\t\t\t" $1}' \
	>> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

while read r;do
    echo -ne "\t$(grep -c ">" ${r})"  >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log && \
	echo -ne "\t\t\t\t\t$(basename ${r})\n"  >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
done < <(grep -Hc ">"  ${var_script_out_data_dir}/*fa | awk -F':' '{print $2 "\t" $1}' | sort --parallel=${ncores} -nr | awk '{print $2}')

echo -e "\nMD5SUMs:\n\tmd5sum\t\t\t\t\tFasta File" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

echo -e "\t$(md5sum ${fastafile})" | \
    awk '{print "\t" $1 "\t" $2}' \
	>> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;

while read r;do
    echo -ne "\t$(md5sum ${r} | awk '{print $1}')" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log && \
	echo -ne "\t$(basename ${r})\n" >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
done < <(grep -Hc ">"  ${var_script_out_data_dir}/*fa | awk -F':' '{print $2 "\t" $1}' | sort --parallel=${ncores} -nr | awk '{print $2}')


rm -fr ${var_script_tmp_data_dir};

# Closing_Log_File
time_execution_stop=$(date +%s)
echo -e "\nFinishing Processing Genome: "${fastafile}" and "${gff}" on: "$(date)"" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "Script Runtime: $(echo "$time_execution_stop"-"$time_execution_start"|bc -l) seconds" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "Script Runtime: $(echo "scale=2;($time_execution_stop"-"$time_execution_start)/60"|bc -l) minutes" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
echo -e "Script Runtime: $(echo "scale=2;(($time_execution_stop"-"$time_execution_start)/60)/60"|bc -l) hours" \
     >> ${var_script_out_data_dir}/00_${fastafile%.fa}_Fasta_GFF3_Eq.log;
exit 0
