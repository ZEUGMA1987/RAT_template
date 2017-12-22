#! /usr/bin/perl
#use Parallel::ForkManager;

#$pm = new Parallel::ForkManager(3); 


$output_path= "/media/rats/create_template";
chdir "$output_path";


@list =`ls -d  cp* `;


$reference="template_1.nii";

foreach $sub (@list)
{
#$pm->start and next; # do the fork	
        chomp($sub);
	$path1 = "$path".'/'."$sub";
	print "$sub\n";
	chdir "$path1";

#`rm T2_$sub.nii`;
`cp T2.nii  $output_path/T2_$sub.nii`;  ### copy T2 from each sub and rename them

####---------- step 1 linear transformation
  `3dAllineate -source T2_$sub -base $reference -prefix allineate_$sub  -twopass -cost lpa -1Dmatrix_save allineate_$sub.tmp.aff12.1D -autoweight -cmass`;

####---------- step 1 linear transformation
  #`align_epi_anat.py -dset1 T2_$sub -dset2 T1NL2_76.nii -dset1to2 -giant_move -cost lpc`;

####---------- step 3 non-linear transformation
  
`3dQwarp -prefix nonline_allineate_$sub -iwarp -duplo -useweight -blur 0 3 -base $reference -source allineate_$sub `;


}

####---------- step 4 average the inverse transformation 
                                                            #  notice: there are three frames in the inverse matrix image; 
  `3dTcat -prefix all_INV_0.nii  nonline_allineate_cp0*INV.nii[0]`;
  `3dTcat -prefix all_INV_1.nii  nonline_allineate_cp0*INV.nii[1]`;
  `3dTcat -prefix all_INV_2.nii  nonline_allineate_cp0*INV.nii[2]`;

   `3dTstat -prefix mean_INV_0.nii -mean all_INV_0.nii`;
   `3dTstat -prefix mean_INV_1.nii -mean all_INV_1.nii`;
   `3dTstat -prefix mean_INV_2.nii -mean all_INV_2.nii`;

   `3dTcat -prefix fin_INV.nii mean_INV_*.nii`; 
   
   
####---------- step 5 
foreach $sub (@list)
{  

`3dNwarpApply -nwarp fin_INV.nii -source nonline_allineate_$sub -prefix inv_nonline_allineate_$sub`; 
}

####---------- step 6
'3dTcat -prefix all_inv_non.nii  inv_nonline_allineate_cp0*'
'3dTstat -mean -prefix mean_all_inv_non.nii all_inv_non.nii'

####---------- step 7
'3dFWHMx mean_all_inv_non.nii'
'3dBlurToFWHM 2 -prefix template_2.nii -input mean_all_inv_non.nii'

print `date\n`;
#$pm->finish;
#die;
}

