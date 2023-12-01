#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

if [ $skip == false ]; 
	then
	#Grab inputs
	dx-download-all-inputs --except ref_genome --parallel

	# make output folders
	mkdir -p ~/out/mpileup_file/coverage/mpileup/ ~/out/mpileup_calcs/coverage/mpileup_calcs/ ./genome

	# make directory for reference genome and unpackage the reference genome
	dx cat "$ref_genome" | tar zxvf - -C genome  
	# => genome/<ref>, genome/<ref>.ann, genome/<ref>.bwt, etc.

	# Parse the reference genome file name for the genome build used and set $genomebuild appropriately.
	# This reference build will be added to the VCF header.
	genomebuild="unknown"
	if [[ $ref_genome_name =~ .*37.* ]]
	then
		genomebuild="grch37"
	elif [[ $ref_genome_name =~ .*19.* ]]
	then
		genomebuild="hg19"
	elif [[ $ref_genome_name =~ .*38.* ]]
	then
		genomebuild="grch38"
	else
		echo "$ref_genome_name does not contain a parsable reference genome name"
	fi

	# rename reference genoms
	mv genome/*.fa  genome/$genomebuild.fa
	mv genome/*.fa.fai  genome/$genomebuild.fa.fai
	# capture the fasta file as a variable for mpileup
	genome_file="genome/*.fa"

	# build the argument string, including the optional inputs if required 
	# -a outputs all bases, even is 0 coverage
	# -B disables BAQ
	# -d max number of reads to count (saves memory - set very high to override default)
	mpileup_opts="-a -B -d 500000"
	if [ "$min_MQ" != "" ]; then
	mpileup_opts="$mpileup_opts -q $min_MQ"
	fi
	if [ "$min_BQ" != "" ]; then
	mpileup_opts="$mpileup_opts -Q $min_BQ"
	fi
	if [ "$bed_file" != "" ]; then
	mpileup_opts="$mpileup_opts -l $bed_file_path"
	fi
	if [ "$mpileup_extra_opts" != "" ]; then
	mpileup_opts="$mpileup_opts $mpileup_extra_opts"
	fi
	echo $mpileup_opts

	for (( i=0; i<${#bam_file[@]}; i++ ))
	do
		# generate an mpileup from bam file
		samtools mpileup -f $genome_file $mpileup_opts -o out/mpileup_file/coverage/mpileup/${bam_file_prefix[i]}.mpileup ${bam_file_path[i]}
		#calculate summary statistics if required
		if [ $mpileup_summary_calcs == true ]; 
		then 
			python3 mpileup_counts.py out/mpileup_file/coverage/mpileup/${bam_file_prefix[i]}.mpileup out/mpileup_calcs/coverage/mpileup_calcs/${bam_file_prefix[i]}.mpileup.calcs
		fi
	done
fi

# upload outputs
dx-upload-all-outputs --parallel