package require xilinx::board 1.0
namespace import ::xilinx::board::*

#Definitional proc to organize widgets for parameters.

proc init_gui { IPINST } {
	set Component_Name [ ipgui::add_param  $IPINST  -parent  $IPINST -name Component_Name ]
	add_board_tab $IPINST
#	set_property ip_complexity "simple" [ipgui::get_canvasspec -of $IPINST]	
	set Page0 [ ipgui::add_page $IPINST  -name "Page 0" -layout vertical]
	set C_MODE [ipgui::add_param $IPINST -parent $Page0 -name C_MODE -widget comboBox]
	set C_FIXED_SPEED [ipgui::add_param $IPINST -parent $Page0 -name C_FIXED_SPEED -widget checkBox]
	set C_SPEED_100 [ipgui::add_param $IPINST -parent $Page0 -name C_SPEED_100 -widget checkBox]
	set C_INCLUDE_BUF [ipgui::add_param $IPINST -parent $Page0 -name C_INCLUDE_BUF -widget comboBox]
    set_property tooltip "(Optional) Insertion of buffer (BUFG/BUFH) in the rx and tx output clock path will help in handling high fanout" $C_INCLUDE_BUF
    set_property tooltip "Fixed ethernet throughput" $C_FIXED_SPEED
    set_property tooltip "Throughput set at 100 Mb/s" $C_SPEED_100
}

proc update_PARAM_VALUE.RMII_BOARD_INTERFACE {IPINST PARAM_VALUE.RMII_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
    set param_range [get_board_interface_param_range $IPINST -name "RMII_BOARD_INTERFACE"]
    set_property range $param_range ${PARAM_VALUE.RMII_BOARD_INTERFACE}
}

proc update_PARAM_VALUE.REF_CLK_BOARD_INTERFACE {IPINST PARAM_VALUE.REF_CLK_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
    set param_range [get_board_interface_param_range $IPINST -name "REF_CLK_BOARD_INTERFACE"]
    set_property range $param_range ${PARAM_VALUE.REF_CLK_BOARD_INTERFACE}
}

proc update_PARAM_VALUE.RESET_BOARD_INTERFACE {IPINST PARAM_VALUE.RESET_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
    set param_range [get_board_interface_param_range $IPINST -name "RESET_BOARD_INTERFACE"]
    set_property range $param_range ${PARAM_VALUE.RESET_BOARD_INTERFACE}
}

proc update_MODELPARAM_VALUE.C_INSTANCE { MODELPARAM_VALUE.C_INSTANCE PARAM_VALUE.Component_Name} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value

	set_property value [get_property value  ${PARAM_VALUE.Component_Name} ]  ${MODELPARAM_VALUE.C_INSTANCE} 

}

proc update_MODELPARAM_VALUE.C_INCLUDE_BUF { MODELPARAM_VALUE.C_INCLUDE_BUF PARAM_VALUE.C_INCLUDE_BUF} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value

	set_property value [get_property value  ${PARAM_VALUE.C_INCLUDE_BUF} ]  ${MODELPARAM_VALUE.C_INCLUDE_BUF} 

}

proc update_MODELPARAM_VALUE.C_FIXED_SPEED { MODELPARAM_VALUE.C_FIXED_SPEED PARAM_VALUE.C_FIXED_SPEED} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    
      if {[ get_property value ${PARAM_VALUE.C_FIXED_SPEED} ]} {
                    set_property value 1  ${MODELPARAM_VALUE.C_FIXED_SPEED} 
      } else {
                    set_property value 0  ${MODELPARAM_VALUE.C_FIXED_SPEED} 
      }
}

proc update_MODELPARAM_VALUE.C_SPEED_100 { MODELPARAM_VALUE.C_SPEED_100 PARAM_VALUE.C_SPEED_100} {

	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
  if {[ get_property value ${PARAM_VALUE.C_SPEED_100} ]} {
				set_property value 1  ${MODELPARAM_VALUE.C_SPEED_100} 
  } else {
				set_property value 0  ${MODELPARAM_VALUE.C_SPEED_100} 
  }

}

proc update_MODELPARAM_VALUE.C_FAMILY {MODELPARAM_VALUE.C_FAMILY PROJECT_PARAM.ARCHITECTURE} {
  set_property value ${PROJECT_PARAM.ARCHITECTURE} ${MODELPARAM_VALUE.C_FAMILY}
}



