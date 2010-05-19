ad_library {

    routines used for modeling cashflows etc
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}

ad_proc -public acc_fin::fp {
    number
} {
    returns a floating point version a number, if the number is an integer (no decimal point).
    tcl math can truncate a floating point in certain cases, such as when the divisor is an integer.
} {
    if { [string first "." $number] < 0 } {
      #  append number ".0"
        set number [expr { double( $number ) } ]
    }
    return $number
} 


ad_proc -private acc_fin::qaf_npv { 
    net_period_list 
    discount_rate_list
    {intervals_per_year 1}
 } {
     Returns the Net Present Value
     In net_period_list, first value is current year, second value is first interval of second year..
     discount_rate_list re-uses the last rate in the list if the list has fewer members than in the cash_flow_list
     Assumes 1 interval per year unless specified
 } {
     set np_sum 0
     set interval 0
     set period_list_count [llength $net_period_list]
     # make lists same length to decrease loop calc time
     set last_supplied_rate [lindex $discount_rate_list end]
     set discount_list_count [llength $discount_rate_list]
     while { $discount_list_count < $period_list_count } {
         lappend discount_rate_list $last_supplied_rate
         incr discount_list_count
     }

     foreach net_period $net_period_list {
         set year_nbr [expr { floor( ( $interval + $intervals_per_year - 1 ) / $intervals_per_year ) } ]
         set discount_rate [lindex $discount_rate_list $internval]
         set current_value [expr { ${net_period} / pow( 1. + $discount_rate , $year_nbr ) } ]
         incr interval
         set np_sum [expr { $np_sum + $current_value } ]
     }
     return $np_sum
 }

ad_proc -private acc_fin::qaf_sign {
    number
} {
    Returns the sign of the number represented as -1, 0, or 1
} {
    set sign [expr { $number / double( abs ( $number ) ) } ]
    return $sign
}

ad_proc -private acc_fin::qaf_discount_npv_curve { 
    net_period_list
    {discounts ""}
    {intervals_per_year 1}
 } {
     Returns a list pair of discounts, NPVs
     uses acc_fin::qaf_npv
 } {
     if { $discounts eq "" } {
         # let's make a sample from a practical range of discounts:
         #0., 0.01, 0.03, 0.07, 0.15, 0.31, 0.63, 1.27, 2.55, 5.11, 10.23, 20.47, 40.95, 81.91
         for {set i 0. } { $i < 100. } {
             lappend discount_list $i
         }
     } else {
         set discount_list [split $discounts " "]
     }

     foreach $i $discount_list {
         lappend irr_curve_list [list $i [acc_fin::qaf_npv $net_period_list [list $i] $intervals_per_year ]]
     }
     return $irr_curve_list
 }

ad_proc -private acc_fin::qaf_irr { 
    net_period_list 
    {intervals_per_year 1}
 } {
     Returns a list of Internal Rate of Returns, ie where NPV = 0.
     Hint: There can be more than one in complex cases.
     uses acc_fin::qaf_npv
 } {
     # let's get a sample from a practical range of discounts:
     #0., 0.01, 0.03, 0.07, 0.15, 0.31, 0.63, 1.27, 2.55, 5.11, 10.23, 20.47, 40.95, 81.91
    
     array npv_test_value
     array npv_test_discount
     set test_nbr 1
     set sign_change_count 0
     for {set i 0. } { $i < 100. } {
         set npv_test_discount(${test_nbr}) $i
         set npv_test_value($test_nbr) [acc_fin::qaf_npv $net_period_list [list $i] $intervals_per_year ]

         if { $test_nbr > 1 } {
             if { [expr {  [acc_fin::qaf_sign $npv_test_value($test_nbr)]  * [acc_fin::qaf::sign $npv_test_value($prev_nbr)] } ] < 0 } {
                 incr sign_change_count
                 lappend start_range $prev_nbr
             }
         }
         set prev_nbr $test_nbr     
     }

     # if $sign_change_count = 0, then there are likely no practical solutions for NPV = 0 within the range
     # find solution through iteration, where npv is Y and discount is X
     set irr_list [list]
     foreach i_begin $start_range {
         set count 0
         set i_end [expr { $i_begin + 1 } ]

         set test_discount $npv_test_discount($i_begin)
         set discount_incr [expr { $test_discount + ( $npv_test_discount($i_end) - $test_discount ) / 10. } ]
         set test_npv npv_tst_value($i_begin)
         set abs_test_npv [expr { abs( $test_npv ) } ]
         # iterate test_discount
         while { $count < 20 and $test_npv ne 0 } {
             incr count
             set new_test_discount [expr { $test_discount + $discount_incr } ]
             set new_test_npv [acc_fin::qaf_npv $net_period_list [$new_test_discount] $intervals_per_year ]             
             set abs_new_test_npv [expr { abs( $new_test_npv ) } ]
             if { $abs_test_npv <= $abs_new_test_npv } {
                 # switch direction, and lower increment
                 set discount_incr [expr ( $discount_incr * -0.5 ) ]
             } 
             set test_discount $new_test_discount
             set test_npv $new_test_npv
         }
         if { $test_npv eq 0 } {
             lappend irr_list $test_discount
         }
     }
     return $irr_list
 }

ad_proc -private acc_fin::qaf_mirr { 
list1 
list2
 } {
 returns the Modified Internal Rate of Return ...
 } {

# code
 }


ad_proc -private acc_fin::qaf_compile_model { 
    model 
} {
     returns calculation friendly list of lists from model represented in shorthand
    shorthand consists of these parts:
section 1: initial calculations and conditions
section 2: repeating calculations (in order calculated)
section 3: list of variables to report with iterations
section 4: analysis calculations
  Each section is separated by a line with '\#'. Be sure to separate variables and operators etc by a space (or more). 
reserved variables:
  i current iteration number, initial conditions are at iteraton 0, whole numbers
  h is i - 1
  timestamp(i) is timestamp associated with period in seconds from system epoch
  dt is duration of a period between timestamp(1) - timestamp(0) in seconds

} {
  # split model by '#' into these parts:
  # 1. initial calculations and conditions (including number of iterations)
  # 2. repeating calculations
  # 3. items to report for each Nth iteration ( starting with iteration number M?)
  # 4. analysis calculations to report at end of iterations

  # then split each section into "lines" by CR

    # then split calculations by "=" (and add set,\[expr \])
    # use ns_write or ad_page_append? for report iterations

  # for security, compiler should not allow square brackets, exec, source, or proc
    set err_state 0
    set err_text 0
    if { [regexp -nocase -- {[^a-z0-9_]exec[^a-z0-9_]} ] } {
        incr err_state
        append err_text "Error: 'exec' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]proc[^a-z0-9_]} ] } {
        incr err_state 
        append err_text "Error: 'proc' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]source[^a-z0-9_]} ] } {
        incr err_state 
        append err_text "Error: 'source' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[\]\[]} ] } {
        incr err_state 
        append err_text "Error: 'square brackets' are not permitted in model definition. \n"
    }

    if { $err_state 0 } {
        set section_count 0
        set model_sections_list [split $model \#]
        set new_model_sections_list [list]
        foreach model_section $model_sections_list {
            incr section_count
            
            if { $section_count < 3 } {
                set section_list [split $model_section \n\r]
                set new_section_list [list]
                foreach calc_line $section_list {
                    if { ![regsub -- {=} $calc_line "\[expr \{ " calc_line] } {
                        append err_text "'${calc_line}' ignored. No equal sign found.\n"
                        incr err_state
                        set $calc_line ""
                    }
                    set calc_line "set ${calc_line} \} \]"
                    set varname [trim [string range ${calc_line} 5 [string first expr $calc_line]-2]]
                    if { ![info exists $varname_list] } {
                        # create list and array history for each variable
                        set ${varname}_list [list]
                        array set ${varname}_arr [list]


                    }
                    if { [string length $calc_line ] > 0 } { 
                        lappend new_section_list $calc_line
                    }
                }
                set section_list $new_section_list
            }
            if { $section_count eq 1 } {
                set new_section_list [list]
                foreach calc_line $section_list {
                    # substitute var_arr(0) for variables on left side
                    set varname [trim [string range ${calc_line} 5 [string first expr $calc_line]-2]]
                    regsub -- $varname $calc_line "${varname}_arr(0)" calc_line
                    # initial period is period 0
                    if { [string length $calc_line ] > 0 } { 
                        lappend new_section_list $calc_line
                    }
                }
                set section_list $new_section_list
            }

            if { $section_count eq 2 } {
                set new_section_list [list]
                foreach calc_line $section_list {
                    # substitute var_arr($i) for variables on left side
                    set varname [trim [string range ${calc_line} 5 [string first expr $calc_line]-2]]
                    regsub -- $varname $calc_line "${varname}_arr(\$i)" calc_line

                    # substitute var_arr($h) for variables on right side
                    # for each string found not an array or within paraenthesis, 
                    regsub -nocase -all -- {[\$]([a-z0-9_]*)[^\(]} $calc_line "\1_arr(\$h)" calc_line
                    if { [string length $calc_line ] > 0 } { 
                        lappend new_section_list $calc_line
                    }
                }
                set section_list $new_section_list
            }



            if { $section_count eq 3 } {
                set section_list [split $model_section \n\r\ \,]
                set new_section_list [list]
                set variables_list [list]
                # report values 
                # convert to list of variables that get converted into a list of lists.
                # to be processed externally (sorted etc)
                foreach named_var $section_list {
                    set named_var [trim $named_var]
                }
                set section_list $new_section_list
            }
            
            if { $section_count eq 4 } {
                set section_list [split $model_section \n\r]
                set new_section_list [list]
                foreach calc_line $section_list {
                    if { ![regsub -- {=} $calc_line {} calc_line] } {
                        append err_text "'${calc_line}' ignored. No equal sign found.\n"
                        incr err_state
                        set $calc_line ""
                    }
                    set calc_line "set ${calc_line}"
                    if { [string length $named_var] > 0 } {
                        lappend variables_list $named_var
                    }
                }
                set section_list $new_section_list
            }
            lappend new_model_sections_list $section_list
        } 
        set model_sections_list $new_model_sections_list
        # return compiled model as list of lists
        return $model_sections_list


    } else {
        set output [list "ERROR: Unable to compile model. ${err_state} Errors. \n ${err_text}" $model_sections_list]
        return $output

    }

}

# when processing, if default_arr(0) exists and var_arr(0) does not exist, set var_arr(0) to $default_arr(0)
