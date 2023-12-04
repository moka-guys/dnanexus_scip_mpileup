###
# Script to parse mpileup files and pull out some summary statistics
# It takes an mpileup file as input and returns a tab delimited text file containing
# summary stats for each position in the file:
# - chromosome, pos, ref base and coverage depth at that position
# - count of the reference base (refered to in the mpileup file as . or ,)
# - counts of each A/C/T/G base NOTE: this will count every occurence of a or A (etc) in the line, which may include inserted or deleted bases
#   this means that around homopolymer tracks there may be a higher number of e.g. A's than the total depth at that position.
# - count of every insertion or deletion that begins at this position (+ or -)
# - count of all deleted bases at that position (*)
# - count of the final bases in the read (^)
# 
# see http://www.htslib.org/doc/samtools-mpileup.html for detailed explanation of the mpileup outputs

# This script takes two inputs
# 1: input filepath/filename
# 2: output filepath/filename
###

import sys

input_filename = sys.argv[1]
output_filename = sys.argv[2]

def mpileup_count(input_file):
    """
    loop through lines in mpileup file and output summary stats
    write summary information to an output file
    """
    output_file = open(output_filename,"a")
    output_file.write(str(input_file)+"\n")
    # write header information to the output file
    output_file.write("chr\tpos\tref\tcov\tref_count\tA_count\tC_count\tT_count\tG_count\tindel_count\tdel_count\tfinal_base_count\n")
    # calculate summary stats per line
    with open(input_file,'r') as mpileup:
        for line in mpileup.readlines():
            chr, pos, ref, depth, base_call_list, qual_list = line.split("\t")
            ref_base_count = base_call_list.count(".") + base_call_list.count(",")
            a_base_count = base_call_list.count("a") + base_call_list.count("A")
            c_base_count = base_call_list.count("c") + base_call_list.count("C")
            t_base_count = base_call_list.count("t") + base_call_list.count("T")
            g_base_count = base_call_list.count("g") + base_call_list.count("G")
            indel_count = base_call_list.count("-") + base_call_list.count("+")
            del_count = base_call_list.count("*")
            count_final_base = base_call_list.count("^")
            # write results to file
            output_file.write(chr+"\t"+str(pos)+"\t"+ref+"\t"+depth+"\t"+str(ref_base_count)+"\t"+str(a_base_count)+"\t"+str(c_base_count)+"\t"+str(t_base_count)+"\t"+str(g_base_count)+"\t"+str(indel_count)+"\t"+str(del_count)+"\t"+str(count_final_base)+"\n")


mpileup_count(input_filename)