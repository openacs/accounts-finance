ad_library {

    standard finance functions 
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}


ad_proc -private acc_fin::qaf_npv { 
    net_period_list 
    discount_rates
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
     if { [llength $discount_rates] > 1 } {
         set discount_rate_list $discount_rates
     } else {
         set discount_rate_list [split $discount_rates]
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
 
         # we need two points to start the iteration

         # first point, the left most range
         set p0_discount $npv_test_discount($i_begin)
         set p0_npv $npv_test_value($i_begin)  
         # first point analysis (for iteration)
         set abs_p0_npv [expr { abs( $p0_npv ) } ]
         set sign_p0_npv [acc_fin::qaf_sign $p0_npv]

         # set interation at a fraction of dx to get a second point within the range
         set discount_incr [expr { ( $npv_test_discount($i_end) - $p0_discount ) / 3. } ]

         # second point is arbitrary between first and last within range
         set p1_discount [expr { $p0_discount + $discount_incr } ]
         set p1_npv [acc_fin::qaf_npv $net_period_list [list $p1_discount] $intervals_per_year ]             
         set abs_p1_npv [expr { abs( $p1_npv ) } ]

         set dx_discount [expr { abs( $p1_discount - $p0_discount ) } ] 

         # iterate
         while { $count < 20 && $abs_p1_npv > 1. && $dx_discount > 1.0e-09 } {
             incr count

             # points are f(p0_discount), f(p1_discount)

             # analyse new point 
             set sign_p1_npv [acc_fin::qaf_sign $p1_npv]
             set sign_change [expr { $sign_p0_npv * $sign_p1_npv } ]

             # is new point getting closer or did we pass NPV=0?
             if { ( $abs_p0_npv < $abs_p1_npv ) || ( $sign_change < 1 ) } {
                 # if passed NPV=0, switch direction and lower increment on next iteration
                 set discount_incr [expr ( $discount_incr * -0.5 ) ]
             } 

             # make 2 guesses, choose closer one.
             # guess0 using iterative method

             set guess0_discount [expr { $p1_discount + $discount_incr } ]
             set guess0_npv [acc_fin::qaf_npv $net_period_list [list $guess0_discount] $intervals_per_year ]             
             set abs_guess0_npv [expr { abs( $guess0_npv ) } ]

             # best guess using linear interpolation between points  f(guess0_discount) and f(p1_discount)
             # slope = dy / dx
             set slope [expr { ( $guess0_npv - $p1_npv ) / double( $guess0_discount - $p1_discount ) } ]
             set try_guess1 [expr { $slope != 0 } ]
             if { $try_guess1 } { 
                 # line not vertical
                 # b = y intercept (x = 0), or approximate: substitute a point in b = y - mx
                 set yintercept [expr { $guess0_npv - ( $slope * $guess0_discount ) } ]
                 # x = (y - b ) / slope
                 set guess1_discount [expr { ( 0. - $yintercept ) / double($slope) } ]
                 set guess1_npv [acc_fin::qaf_npv $net_period_list [list $guess1_discount] $intervals_per_year ]             
                 set abs_guess1_npv [expr { abs( $guess1_npv ) } ]
             }

             # save old point
             set p0_discount $p1_discount
             set p0_npv $p1_npv
             set sign_p0_npv $sign_p1_npv
             set abs_p0_npv $abs_p1_npv

             # choose the closest new point, if there is a choice
             if { ( $try_guess1 && $abs_guess1_npv < $abs_guess0_npv ) } {

                 set p1_discount $guess1_discount
                 set p1_npv $guess1_npv
                 set abs_p1_npv $abs_guess1_npv
                 # choose minimum nonzero dx
                 set guess1_dx [expr { $guess1_discount - $p0_discount} ]
                 set guess0_dx [expr { $guess0_discount - $p0_discount } ]
                 set abs_guess1_dx [expr { abs($guess1_dx) } ]
                 set abs_guess0_dx [expr { abs($guess0_dx) } ]

                 if { $abs_guess1_dx > 0. && $abs_guess0_dx > 0. } {
                     # set discount_incr smaller of either (f::min) expr {$x<$y ? $x : $y}                 
                     set discount_incr [expr { $abs_guess1_dx < $abs_guess0_dx ? $guess1_dx : $guess0_dx } ]
                 } else {
                     # set discount_incr to larger of either (f::min) expr {$x<$y ? $x : $y}
                     set discount_incr [expr { $abs_guess1_dx > $abs_guess0_dx ? $guess1_dx : $guess0_dx } ]
                 }
             } else {
                 set p1_discount $guess0_discount
                 set p1_npv $guess0_npv
                 set abs_p1_npv $abs_guess0_npv
             }

             set dx_discount [expr { abs( $p1_discount - $p0_discount ) }  ]
        }
 
         if { $abs_p1_npv < 1. } {
             lappend irr_list $p1_discount
         }
     }
     return $irr_list
 }

ad_proc -private acc_fin::qaf_mirr { 
    period_cf_list 
    finance_rate
    re_invest_rate
    {intervals_per_year 1}
 } {
     Returns a Modified Internal Rate of Return
 } {
     # see http://en.wikipedia.org/wiki/Modified_internal_rate_of_return
     # create separate positive and negative cashflows from list

     set period_count [llength $period_cf_list]
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
     set mirr [expr { pow( ( -1. * $fv ) / double( $pv ), 1. / ( double( $period_count ) -1. ) ) - 1. } ]
     return $mirr
 }

ad_proc -private acc_fin::qaf_loan_payment { 
    principal
    annual_interest_rate
    intervals_per_year
    years
 } {
    Returns regular payment for loan.
    Interest is compounded per interval (period). Assumes payment is made at end of interval.
 } {
     # interval interest rate
     set interval_rate [expr { $annual_interest_rate / double($intervals_per_year) } ]
     set regular_payment [expr { ( $principal * $interval_rate ) / ( 1. - exp( -1. * $intervals_per_year * $years * log( 1. + $interval_rate ) ) ) ) } ]
     return $regular_payment
 }

ad_proc -private acc_fin::qaf_loan_apr { 
    annual_interest_rate
    intervals_per_year
 } {
    Returns regular payment for loan.
    Interest is compounded per interval (period).
 } {
     set apr [expr {  pow( 1. + $annual_interest_rate / double($intervals_per_year) , $intervals_per_year ) - 1. } ]

     return $apr
 }

ad_proc -private acc_fin::qaf_compound_interest { 
    principal
    annual_interest_rate
    intervals_per_year
    years
 } {
    Returns principal and compounded interest 
    Interest is compounded per interval (period). 
 } {
     set principal_and_interest [expr { $principal * pow( 1. + $annual_interest_rate / double($intervals_per_year) , double ($intervals_per_year * $years ) ) } ]
     return $principal_and_interest
 }

ad_proc -private acc_fin::qaf_loan_model { 
    principal
    annual_interest_rate
    intervals_per_year
    years
    {payments ""}
    {query_period "summary"}
 } {
    Provides table of common loan data for complex modeling.
    Interest is compounded per interval (period). 
    If a list of payments are supplied, they are applied in order with first payment at end of period 1. Second payment at end of period 2 etc. and final payment is repeated until loan is paid in full or number of loan years is complete.
    If no payments are supplied, a constant payment is calculated and assumed.
     Returns elements of query in list pairs of period number provided. Period 0 is before loan begins. Use "summary" to return summary accumulations. "all" to return all data as list of lists. 
 } {
     if { $payments eq "" } {
         set payments [acc_fin::qaf_loan_payment $principal $annual_interest_rate $intervals_per_year $years]
     }
     # convert payments to a list, in case it was supplied as a scalar
     if { [llength $payments] > 1 } {
         set payment_list $payments
     } else {
         set payment_list [split $payments]
     } 
     set last_supplied_pmt [lindex $payments_list end]
     set payments_list_count [llength $payments_list]
     set periods_count [expr { ( intervals_per_year * years ) } ]
     while { $payments_list_count < $periods_count } {
         lappend payments_list $last_supplied_pmt
         incr payments_list_count
     }


     return $query_report_list
 }
