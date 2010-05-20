ad_library {

    standard finance functions 
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}


ad_proc -private acc_fin::qaf_npv { 
    net_period_list 
    discount_rates_list
    {intervals_per_year 1}
 } {
     Returns the Net Present Value
     In net_period_list, first value is current year, second value is first interval of second year..
     discount_rate_list re-uses the last rate in the list if the list has fewer members than in the cash_flow_list
     Assumes 1 interval per year unless specified, rates are annual
 } {
     set np_sum 0.
     set interval 0
     set period_list_count [llength $net_period_list]

     # make lists same length to decrease loop calc time
     # convert discount_rates to a list, in case it was supplied as a scalar
     if { [llength $discount_rates_list] > 1 } {
         set discount_rate_list $discount_rates_list
     } else {
         set discount_rate_list [split $discount_rates_list]
     }
     set last_supplied_rate [lindex $discount_rate_list end]
     set discount_list_count [llength $discount_rate_list]
     while { $discount_list_count < $period_list_count } {
         lappend discount_rate_list $last_supplied_rate
         incr discount_list_count
     }
     # calc npv
     foreach net_period $net_period_list {
         set year_nbr [expr { floor( ( $interval + $intervals_per_year - 1 ) / $intervals_per_year ) } ]
         set discount_rate [lindex $discount_rate_list $interval]
         set current_value [expr { ${net_period} / pow( 1. + double($discount_rate) , $year_nbr ) } ]
         incr interval
         set np_sum [expr { $np_sum + $current_value } ]
     }
     return $np_sum
 }

ad_proc -private acc_fin::qaf_fvsimple { 
    net_period_list 
    annual_interest_rate
    {intervals_per_year 1}
 } {
     Returns Future Value of a series of periods using simple interest
     The last period in the list is considered the target Future period.
     Assumes 1 interval per year unless specified
 } {
     set fv_sum 0.
     set interval 0
     set period_list_count [llength $net_period_list]

     for {set i 0} {$i < $period_list_count} {incr i}  {
         set net_period [lindex $net_period_list $i]
         set interval [expr { $period_list_count - $i - 1 } ]
         set year_nbr [expr { floor( ( $interval + $intervals_per_year - 1 ) / $intervals_per_year ) } ]
         set current_value [expr { ${net_period} * pow( 1. + double($annual_interest_rate) , $year_nbr ) } ]
         incr interval
         set fv_sum [expr { $fv_sum + $current_value } ]
     }
     return $fv_sum
 }

ad_proc -private acc_fin::qaf_discount_npv_curve { 
    net_period_list
    {discounts ""}
    {intervals_per_year 1}
 } {
     Returns a list pair of discounts, NPVs over a range of discounts
     uses acc_fin::qaf_npv
 } {
   set discount_list [list]
     if { [string length $discounts] < 2 } {
         # let's make a sample from a practical range of discounts:
         #0., 0.01, 0.03, 0.07, 0.15, 0.31, 0.63, 1.27, 2.55, 5.11, 10.23, 20.47, 40.95, 81.91
         for {set i 0. } { $i < 100. } { set i [expr { $i * 2. + .01 } ] } {
             lappend discount_list $i
         }
     } elseif { [llength $discounts] > 1 } {
         set discount_list $discounts
     } else {
         set discount_list [split $discounts " "]
     }
     set npv_curve_list [list]
     foreach i $discount_list {
         lappend npv_curve_list [list $i [acc_fin::qaf_npv $net_period_list [list $i] $intervals_per_year ]]
     }
     return $npv_curve_list
 }

ad_proc -private acc_fin::qaf_irr { 
    net_period_list 
    {intervals_per_year 1}
 } {
     Returns a list of Internal Rate of Returns, ie where NPV = 0.
     Hint: There can be more than one in complex cases.
     uses acc_fin::qaf_npv
 } {
# proc acc_fin::qaf_irr { net_period_list {intervals_per_year 1} } {
     # let's get a sample from a practical range of discounts:
     #0., 0.01, 0.03, 0.07, 0.15, 0.31, 0.63, 1.27, 2.55, 5.11, 10.23, 20.47, 40.95, 81.91
    
     array set npv_test_value [list]
     array set npv_test_discount [list]
     set test_nbr 1
     set sign_change_count 0
     set start_range [list]
     for {set i 0. } { $i < 100. } { set i [expr { $i * 2. + .01 } ] } {
         set npv_test_discount(${test_nbr}) $i
         set npv_test_value($test_nbr) [acc_fin::qaf_npv $net_period_list [list $i] $intervals_per_year ]

         if { $test_nbr > 1 } {
             if { [expr {  [acc_fin::qaf_sign $npv_test_value($test_nbr)] * [acc_fin::qaf_sign $npv_test_value($prev_nbr)] } ] < 0 } {
                 incr sign_change_count
                 lappend start_range $prev_nbr
             }
         }
         set prev_nbr $test_nbr     
         incr test_nbr
     }

     # if $sign_change_count = 0, then there are likely no practical solutions for NPV = 0 within the range
     # find solution through iteration, where npv is Y and discount is X
     set irr_list [list]
     foreach i_begin $start_range {

         set count 0
         set i_end [expr { $i_begin + 1 } ]

 
         # let's do our best first guess using linear interpolation
         # first point
         set test_discount $npv_test_discount($i_begin)
         set test_npv $npv_test_value($i_begin)  
         # first point analysis (for iteration)
         set abs_test_npv [expr { abs( $test_npv ) } ]
         set sign_test_npv [acc_fin::qaf_sign $test_npv]

         # set interation at one tenth of dx to get a second point within the range
         set discount_incr [expr { ( $npv_test_discount($i_end) - $test_discount ) / 10. } ]

         # arbitrary second point between first and last within range
         set new_test_discount [expr { $test_discount + $discount_incr } ]
         set new_test_npv [acc_fin::qaf_npv $net_period_list [list $new_test_discount] $intervals_per_year ]             

  
         # best guess using available points and linear interpolation
         # slope = dy / dx
         set slope [expr { ( $new_test_npv - $test_npv ) / double( $new_test_discount - $test_discount ) } ]
         # b = y intercept (x = 0), or approximate: substitute a point in b = y - mx
         set yintercept [expr { $new_test_npv - ( $slope * $new_test_discount ) } ]
         # x = (y - b ) / slope
         set new_test_discount [expr { ( 0. - $yintercept ) / $slope } ]
         set new_test_npv [acc_fin::qaf_npv $net_period_list [list $test_discount] $intervals_per_year ]             


puts "i_begin $i_begin, discount_incr $discount_incr, npv_test_discount(i_end) $npv_test_discount($i_end)"
         # iterate test_discount

         while { $count < 20 && $test_npv ne 0. } {
             incr count


             # new point
             set new_test_discount [expr { $test_discount + $discount_incr } ]
             set new_test_npv [acc_fin::qaf_npv $net_period_list [list $test_discount] $intervals_per_year ]             
             # analyse
             set abs_new_test_npv [expr { abs( $new_test_npv ) } ]
             set sign_new_test_npv [acc_fin::qaf_sign $new_test_npv]
             set sign_change [expr { -1 * $sign_test_npv * $sign_new_test_npv } ]
             # is new point getting closer or did we pass NPV=0?
             if { $abs_test_npv < $abs_new_test_npv || $sign_change eq 1. } {
                 # if not, switch direction, and lower increment on next iteration
                 set discount_incr [expr ( $discount_incr * -0.5 ) ]
             } 

             set test_discount $new_test_discount
             set test_npv $new_test_npv
             set sign_test_npv $sign_new_test_npv
puts "count $count, test_npv $test_npv, test_discount $test_discount, sign_change $sign_change, discount_incr $discount_incr" 
        }
 
         if { $test_npv eq 0 } {
             lappend irr_list $test_discount
         }
     }
     return $irr_list
 }

ad_proc -private acc_fin::qaf_mirr { 
    net_period_list 
    finance_rate
    re_invest_rate
    {intervals_per_year 1}
 } {
     Returns a Modified Internal Rate of Return
 } {
     # create separate positive and negative cashflows from list
     set period_count [llength $net_period_list]
     foreach period_cf $period_cf_list {
         if { $period_cf > 0 } {
             lappend positive_cf_list $period_cf
             lappend negative_cf_list 0
         } else {
             lappend positive_cf_list 0
             lappend negative_cf_list $period_cf
         }
     }
     set pv [acc_fin::qaf_npv $negative_cf_list [list $finance_rate] $intervals_per_year]
     set fv [acc_fin::qaf_fvsimple $positive_cf_list $re_invest_rate $intervals_per_year]
     set mirr [expr { pow( -1. * $fv / double( $pv ), 1. / double( $period_count ) ) - 1. } ]
     return $mirr
 }
