#!/usr/bin/env bash
#author: Theodor Mayer & Ran Feng
#contact: theodor.mayer@uconn.edu
################################################
# user defined tagging regions and tracer species
###############################################
tracking=( 0 1 1 1 ) #which iso (isph2o isph216o isphdo isph218o) to track, include = 1, dont include = 0
####################################
#isotope tag for the output history file - inputs for make_namelist.sh to set up user_nl_cam
## the naming convention for the output variables is {loctags}{topetags}
export topetags=( _16 _D _18 ) #corresponding to the tagged water species
####################################
#region tag from water tagging: for both make_tag.sh and make_namelist.sh
export loctags=( LND NPAC )
####################################
# for the namelist, cannot be H2O, H216O, HD16O or H218O
export species=( H216O HD16O H218O )
# whether to tag evaporation from ocean, land or ice
ifocn=( 0 1 )
iflnd=( 1 0 )
ifice=( 0 0 )
##################################### 
### latitude, longitude bound:needs to be integers
##       latupp 
#  lonlow      lonupp
##      latlow
latlow=( -90 30 ) #lat lower bound 
latupp=( 90  60 )  #lat upper bound
lonlow=( 0   120 ) #lon lower bound
lonupp=( 360 250 ) #lon upper bound
#############################
#internal definitions of the code : no need to change, unless the code base is changed
#############################
###case name of different water species
casename=( isph2o isph216o isphdo isph218o )
#############################
# the coded tags for different species in evaporation and condensation
#############################
evaptags=( "" _16O _HDO _18O )
jind=5  # indices for counting tracers, starting with 5, first four are H2O, H216O, H218O and HDO
#############################
# end of internal definition
############################
## record the section of code for water tagging as a temporary file
rm -rf tag_section.temp
touch  tag_section.temp 
###########################
if [[ ${#tracking[*]} > 4 ]] ; then
	echo "tracking option can only have four elements"	
fi
for i in ${!tracking[@]}; do
        if [[ ${tracking[i]} == 0 ]] ;then
####  not tracking ${casename[i]} 
echo "
              case (${casename[i]})
                cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = -x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
#### "tracking ${casename[i]}"
        elif [[ ${tracking[i]} == 1 ]] ;then
### i+1 is the fortran index, which starts at 1
echo "
              case (${casename[i]})
                if(j .eq. $(($i + 1))) then 
                  cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = -x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig)
                else !water tag
                  if( -x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) .lt. 0._r8) then !dew/frost?
                    !calculate surface vapor ratio:
                     R = wtrc_ratio(wtrc_species(wtrc_iasrfvap(j)),cam_out(c)%qbot(i,wtrc_indices(wtrc_iasrfvap(j))),&
                                    cam_out(c)%qbot(i,wtrc_indices(wtrc_iasrfvap(1))))
                      cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = R*-x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
echo "             else "       													>> tag_section.temp
		for j in ${!loctags[@]}; do
echo "                  if(j .eq. ${jind}) then "											>> tag_section.temp
echo "                    !${loctags[j]}${evaptags[i]}:
                           if(((wtlat > ${latlow[j]}._r8) .and. (wtlat < ${latupp[j]}._r8)) .and. ((wtlon > ${lonlow[j]}._r8) .and. (wtlon <= ${lonupp[j]}._r8))) then " >> tag_section.temp
                if [[ ${ifocn[j]} == 1 ]]; then
echo "                             cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = (1._r8-cam_in(c)%landfrac(i))*-x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
		elif [[ ${ifice[j]} == 1 ]]; then
echo "                             cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = (1._r8-cam_in(c)%landfrac(i)-cam_in(c)%ocnfrac(i))*-x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
		elif [[ ${iflnd[j]} == 1 ]]; then
echo "                             cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = cam_in(c)%landfrac(i)*-x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
		else	
echo "                             cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = -x2a_a%rAttr(index_x2a_Faxx_evap${evaptags[i]},ig) " >> tag_section.temp
		fi
echo "                    else
                              cam_in(c)%cflx(i,wtrc_indices(wtrc_iasrfvap(j))) = 0._r8
                          end if 
                 end if " >> tag_section.temp
###############only add the last part to the end of the if statements within the loop
                if [[ $(($j+1)) == ${#loctags[@]} ]]; then
echo "
                  end if   !dew/frost
                end if     !H2O tracer " >> tag_section.temp
                fi
###############advance the counter for counting tracers
		     jind=$(($jind + 1))
		done 
	else
		echo "tracking value must be 0 or 1"
	fi
done
################# end of constructing the water tagging code, temporary output is tag_section.temp
### check if atm_comp_mct.F90 already exists in the current folder
nlines=`wc -l < tag_section.temp`
rlines=`awk '/water\ tag\ goes\ here/{print NR}' atm_comp_mct_template_F90`

if [[ -f atm_comp_mct.F90 ]]; then
   read -p "found existing atm_comp_mct.F90. wish to delete? (yes or no)" yn
   case $yn in
        [Yy]* ) rm atm_comp_mct.F90 ; 
	### insert the section of code with water tagging
		sed ''${rlines}' e sed -n 1,'${nlines}'p tag_section.temp' atm_comp_mct_template_F90 > atm_comp_mct.F90 ;
		rm tag_section.temp ;;
        [Nn]* ) echo "nothing is done to atm_comp_mct.F90; partial code is saved as tag_section.temp" ;;
   esac
else
		sed ''${rlines}' e sed -n 1,'${nlines}'p tag_section.temp' atm_comp_mct_template_F90 > atm_comp_mct.F90
		rm tag_section.temp
fi
################
### check if user_nl_cam already exists in the current folder; and whether the user wants to append a new section
### of water tagging setup
if [[ -f user_nl_cam ]]; then
   read -p "found existing user_nl_cam. Wish to append namelist settings for water tagging to the existing file? (yes or no)" yn
   case $yn in
        [Yy]* ) source ./make_namelist.sh ;;
        [Nn]* ) echo "nothing is done to user_nl_cam" ;;
   esac
else
	source ./make_namelist.sh
fi
###run 
