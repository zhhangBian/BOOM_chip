#####Upgrades TCL file
if {![namespace exists xcoUpgradeLib]} {

namespace eval mii_to_rmii_v2_0_utils {


        proc upgrade_from_mii_to_rmii_v1_01_a {xciValues} {

          upvar $xciValues valueArray
          namespace import ::xcoUpgradeLib::*

          return
        }
   }

} ;# end namespace
