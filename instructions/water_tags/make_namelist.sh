#!/usr/bin/env bash
## Author: Theodor Mayer & Ran Feng
## To report bug, please contact theodorm@uconn.edu
## This script uses the location tags and isotope tages to set up namelist for water tagging function in CAM5
## It can be used as a standalone tool,
## or part of the make_tag.csh to set up the namelist after constructing the tagging code
###### for standalone execution
#loctags=( LND OCN NP WEP EEP WNP ENP WSP ESP SO TIN EAM AM )
#topetags=(_W _16 _D _18) # water, h216O, hDO or h218O (corresponding to the tagged species)
#############################
#set up wtrc_names, > overwrite, >> add
echo "making namelist file for tagged regions and water species"
echo ${loctags[*]} 
echo ${topetags[*]}
species=(H2O H216O HD16O H218O)
wtrc_tails=(V L I R S r s)
pcp_tails=(R S r s)

if [[ ! -f user_nl_cam ]] ; then
	touch user_nl_cam
fi
###################################
cat << EOF >> user_nl_cam 
wtrc_names             = 'H2OV', 'H2OL', 'H2OI', 'H2OR', 'H2OS', 'H2Or', 'H2Os',
                          'H216OV', 'H216OL', 'H216OI','H216OR','H216OS','H216Or', 'H216Os',
                          'HDOV','HDOL', 'HDOI', 'HDOR', 'HDOS', 'HDOr', 'HDOs',
                          'H218OV', 'H218OL', 'H218OI', 'H218OR', 'H218OS', 'H218Or', 'H218Os',
EOF
#########loop through to set the wtrc_names
for topetag in ${topetags[*]}
do
for loctag in ${loctags[*]} 
do
cat << EOF >> user_nl_cam
	                  '$loctag$topetag${wtrc_tails[0]}','$loctag$topetag${wtrc_tails[1]}', '$loctag$topetag${wtrc_tails[2]}', '$loctag$topetag${wtrc_tails[3]}', '$loctag$topetag${wtrc_tails[4]}', '$loctag$topetag${wtrc_tails[5]}', '$loctag$topetag${wtrc_tails[6]}',
EOF
done
done
truncate -s-2 user_nl_cam
echo "" >> user_nl_cam
### done of loop
##############set up wtrc_srfpcp_names
cat << EOF >> user_nl_cam
wtrc_srfpcp_names          =  'H2OR', 'H2OS', 'H2Or', 'H2Os',
                              'H216OR', 'H216OS', 'H216Or', 'H216Os',
                              'HDOR', 'HDOS', 'HDOr', 'HDOs',
                              'H218OR', 'H218OS', 'H218Or', 'H218Os',
EOF
for topetag in ${topetags[@]}
do
for loctag in ${loctags[@]}
do
cat << EOF >> user_nl_cam
                              '$loctag$topetag${pcp_tails[0]}','$loctag$topetag${pcp_tails[1]}', '$loctag$topetag${pcp_tails[2]}', '$loctag$topetag${pcp_tails[3]}',
EOF
done
done
truncate -s-2 user_nl_cam
echo "" >> user_nl_cam
#############set up wtrc_species_names
cat << EOF >> user_nl_cam
wtrc_species_names         = 'H2O', 'H2O', 'H2O', 'H2O', 'H2O', 'H2O', 'H2O',
                             'H216O', 'H216O', 'H216O', 'H216O', 'H216O', 'H216O', 'H216O',
                             'HD16O', 'HD16O', 'HD16O', 'HD16O', 'HD16O', 'HD16O', 'HD16O',
                             'H218O', 'H218O', 'H218O', 'H218O', 'H218O', 'H218O', 'H218O',
EOF
for i in ${!topetags[@]} ##give us array indexes
do
for j in ${loctags[*]}
do
cat << EOF >> user_nl_cam
	                     '${species[i]}', '${species[i]}', '${species[i]}', '${species[i]}', '${species[i]}', '${species[i]}', '${species[i]}',
EOF
done 
done
truncate -s-2 user_nl_cam
echo "" >> user_nl_cam
############set up the  wtrc_srfvap_names              = 'H2OV', 'H216OV', 'HDOV','H218OV',
cat << EOF >> user_nl_cam
wtrc_srfvap_names              = 'H2OV', 'H216OV', 'HDOV','H218OV',
EOF
for topetag in ${topetags[*]}
do
for loctag in ${loctags[*]}
do
cat << EOF >> user_nl_cam
			         '${loctag}${topetag}V',
EOF
done 
done
truncate -s-2 user_nl_cam
echo "" >> user_nl_cam
########set up wtrc_type_names
cat << EOF >> user_nl_cam
wtrc_type_names           =  
EOF
truncate -s-1 user_nl_cam
c=$((${#topetags[*]}*${#loctags[*]}))+4
for ((i=0; i<$c; i++))
do
cat << EOF >> user_nl_cam
'VAPOR', 'LIQUID', 'ICE', 'RAINS', 'SNOWS', 'RAINC', 'SNOWC',
EOF
done
truncate -s-2 user_nl_cam
echo "" >> user_nl_cam
