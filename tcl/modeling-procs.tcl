ad_library {

    routines used for modeling cashflows etc
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}

ad_proc -public qaf_tcl_list_of_lists_to_html_table {
    tcl_list_of_lists
    {formatting_list ""}
    {first_are_titles "0"}
    {watch_print_row "1"}
    {separate_uniques "1"}
} {
    returns an html table where each cell is an item from a tcl list of lists, where 
    the first item of each list is the first row, the second item of each list is the second row etc etc.
    the table has the same number of rows as the maximum count of list items, and
    the same number of columns as there are lists.  Lists with too few list items are filled with empty cells.
    Converts first row to titles if first_are_title is true (1).
    If watch_print_row is 1, and the first item in one of the lists is "print_row", the column will not be printed and subsequent rows where the value of column print_row is 0 will be ignored.
    Formatting_list items are tcl format specifications applied to the values in the cooresponding tcl_list_of_list columns, one spec per column.
    If separate_uniques is true, columns that have only 1 row are presented as a separate table, oriented as a column of values
} {
    set columns_count [llength $tcl_list_of_lists]
    set formatting_p [expr { [llength $formatting_list] == $columns_count } ]

    set column_to_hide -1
    set rows_count 0
    set column_number 0
    foreach column_list $tcl_list_of_lists {
        set row_count($column_number) [llength $column_list]
        set true_column($column_number) [expr { ( ( $separate_uniques && $row_count($column_number) > 2 ) || $separate_uniques != 1 ) } ]
        set rows_count [expr { [f::max $rows_count $row_count($column_number) ] } ]
        if { $watch_print_row } {
            if { [lindex $column_list 0] eq "print_row" } {
                set column_to_hide $column_number
            }
        }
        if { $formatting_p } {
            set format_spec($column_number) [lindex $formatting_list $column_number]
        }
        incr column_number
    }

    set table_html "<table border=\"1\" cellspacing=\"0\" cellpadding=\"3\">\n"
    if { $first_are_titles } {
        set cell_tag "th"
    } else {
        set cell_tag "td"
    }

    for {set row_index 0} { $row_index < $rows_count } { incr row_index 1 } {

        # check to see if we should be ignoring this row
        if { $column_to_hide == -1 || ($column_to_hide > -1 && [expr { round( [lindex [lindex $tcl_list_of_lists $column_to_hide ] $row_index] ) } ] != 0 ) } {
            # process row
            set row_html "<tr>"
            set format_row_p [expr { ( $first_are_titles != 0 && $row_index > 0 ) || ( $first_are_titles == 0 ) } ]
            for {set column_index 0} { $column_index < $columns_count } { incr column_index 1 } {
                if { $column_index != $column_to_hide && $true_column($column_index) } {
                    # process this column / cell
                    set cell_value [lindex [lindex $tcl_list_of_lists $column_index ] $row_index]
                    if { $formatting_p && $format_row_p } {
                        if { [catch { set cell_value [format $format_spec($column_index) $cell_value] } result_msg] } {
                            set cell_value "format error(spec,value): $format_spec(${column_index}) ${cell_value}"
                        } 
                    } 
                    set cell_html "<${cell_tag}>${cell_value}</${cell_tag}>"
                    append row_html $cell_html
                }
            }
            append row_html "</tr>\n"
            append table_html $row_html
        } else {
            append table_html "<tr><td colspan=\"$columns_count\">(blank row ${row_index})</td></tr>"
        }
        # next row
        set cell_tag "td"
    }

    append table_html "</table>\n"
    # now we handle the data with unique (only one value) in a column


    set table_2_html "<table border=\"1\" cellspacing=\"0\" cellpadding=\"3\">\n"
    set row_html ""
    set format_row_p [expr { ( $first_are_titles != 0 && $row_index > 0 ) || ( $first_are_titles == 0 ) } ]
    for {set column_index 0} { $column_index < $columns_count } { incr column_index 1 } {
        if { $column_index != $column_to_hide && $true_column($column_index) == 0 } {
            # process this column / cell
            set cell_heading [lindex [lindex $tcl_list_of_lists $column_index ] 0]
            set cell_value [lindex [lindex $tcl_list_of_lists $column_index ] 1]
            if { $formatting_p && $format_row_p } {
                if { [catch { set cell_value [format $format_spec($column_index) $cell_value] } result_msg] } {
                    set cell_value "format error(spec,value): $format_spec(${column_index}) ${cell_value}"
                } 
            } 
            set cell_html "<tr><td>${cell_heading}</td><td>${cell_value}</td></tr>"
            append row_html $cell_html
        }
    }
    append table_2_html $row_html
    append table_2_html "</table>"

    append table_2_html $table_html

    return $table_2_html
} 

ad_proc -public qaf_fp {
    number
} {
    returns a floating point version a number, if the number is an integer (no decimal point).
    tcl math can truncate a floating point in certain cases, such as when the divisor is an integer.
    Use double() instead when referencing a value in an expr.
} {
    if { [string first "." $number] < 0 } {
      #  append number ".0"
        catch { 
            set number [expr { double( $number ) } ] 
        } else {
            # do nothing. $number is not a recognized number
        }
    }
    return $number
} 


ad_proc -public qaf_sign {
    number
} {
    Returns the sign of the number represented as -1, 0, or 1
} {
    if { $number == 0 } {
        set sign 0
    } else {
        set sign [expr { round( $number / double( abs ( $number ) ) ) } ]
    }
    return $sign
}

ad_proc -public acc_fin::list_set {
    list_of_values
    {delimiter " "}
} {
    Returns a list_of_values in tcl list format. This allows the model to use tcl list without complicating permissions.
} {
    if { [string length $delimiter] == 0} {
        set delimiter " "
    }
    set max_index [llength $list_of_values]
    if { $max_index > 1 } {
        set values_list $list_of_values
     } else {
         set values_list [split $list_of_values $delimiter]
     }
    return $list_of_values
} 


ad_proc -public acc_fin::list_index {
    list_of_values
    index_ref
    {default_value "0"}
} {
    Returns the value of the list at index_ref where the first value is 0. If the reference is not valid or out of range, returns the default value ( 0 by default), or the last value of the list if default is blank.
} {
    set index_ref [expr { round( $index_ref ) } ]
    set max_index [llength $list_of_values]
    if { $max_index > 1 } {
        set values_list $list_of_values
     } else {
         set values_list [split $list_of_values]
     }
     set values_list_count [llength $values_list]
    if { $index_ref > -1 && $index_ref < $values_list_count } {
        set return_value [lindex $values_list $index_ref]
    } elseif { [string length $default_value] > 0 } {
        set return_value $default_value
    } else {
        set return_value [lindex $values_list end]
    }
} 

ad_proc -public acc_fin::list_indexes {
    list_of_values
    list_of_indexes
    {default_value "0"}
} {
    Returns a list of  values of the list_of_values for each index in list_of_indexes.  The first value is at index  0. If an index reference is not valid or out of range, returns the default value ( 0 by default), or the last value of the list_of_values if default is blank.
} {

    if { [llength $list_of_values] > 1 } {
        set values_list $list_of_values
    } else {
        set values_list [split $list_of_values]
    }
    set values_list_count [llength $values_list]
    
    if { [llength $list_of_indexes] > 1 } {
        set indexes_list $list_of_indexes
    } else {
        set indexes_list [split $list_of_indexes]
    }
    set indexes_list_count [llength $indexes_list]
    
    set new_list_of_values [list]
    foreach index $list_of_indexes {
        lappend new_list_of_values [acc_fin::list_index $list_of_values $index $default_value]
    }
    return $new_list_of_values
} 

ad_proc -public acc_fin::list_sorted_indexes {
    list_of_values 
    {sort_type "-real"}
} {
    Returns a list of indexes of the list_of_values that puts the list_of_values in sorted order. This is useful for reports, where the same sort needs to be applied on multiple lists. This output, when supplied to list_indexes, returns a list of sorted values. see tcl lsort for sort_type options.
} {
    if { [llength $list_of_values] > 1 } {
        set values_list $list_of_values
    } else {
        set values_list [split $list_of_values]
    }
    set values_list_count [llength $values_list]
    set values_sorted_list [lsort $sort_type $values_list]
    set index_sorted_list [list]
    foreach value $values_sorted_list {
        set propose_index [lsearch -exact $values_list $value]
        while { [lsearch -exact $propose_index $index_sorted_list] > -1 } {
            incr propose_index
            set propose_index [lsearch -exact -start $propose_index  $values_list $value]
        }
        lappend index_sorted_list $propose_index
    }
    return $index_sorted_list
}

ad_proc -public acc_fin::list_summary_indexes {
    list_of_values
} {
    Returns a list of indexes of the list_of_values, where only the last value in a sequence of same numbers is used. This is useful for identifying  end_of_period iterations in a list where multiple iterations occur within the same period. For example, in a list of years, year "10" may be for iterations 120 through 131 when iterated monthly. For this example, the value 131 is returned for this year as the last in the index for that year. A second value for "10" is added, if "10" appears in a sequence later in the list. 
} {
    if { [llength $list_of_values] > 1 } {
        set values_list $list_of_values
    } else {
        set values_list [split $list_of_values]
    }
    set values_list_count [llength $values_list]
    set indexes_unique_list [list]
    if { $values_list_count > 1 } {
        set last_value [lindex $values_list 0]
        for {set index 1} {$index < $values_list_count } { incr index 1} {
            set last_index [expr $index - 1]
            set value [lindex $values_list $index]
            if { $value ne $last_value && $last_index > -1  } {
                lappend indexes_unique_list $last_index
            }
            set last_value $value
        }
        lappend indexes_unique_list $index
        
    } elseif { $values_list_count == 1 } {
       lappend indexes_unique_list 0
    }
    return $indexes_unique_list
}


ad_proc -public acc_fin::inflation_factor {
    annual_inflation_rate
    intervals_per_year
    year
} {
    Returns the factor to apply to a value to adjust for inflation.
    Assumes inflationary factors occur once per year at end of year.
} {
    set inflationary_factor [expr { pow ( 1. + $annual_inflation_rate / double($intervals_per_year) , $year - 1. ) } ]
}

ad_proc -private acc_fin::template_model { 
    template_number
} {
    returns a template for financial modelling
    0 is for testing
} {
    switch -exact -- $template_number {
        0 { set template "
default = 0
a1000_ASSETS  = 0
a1010_Cash = 0
a1020_Inventories = 0
a1030_AR = 0
a1040_Prepaid_exp = 0
a1050_PPE = 0
a1060_Real_estate = 0
a1070_Intangible_assets = 0
a1080_other_fin_assets = 0
a1090_equity_investments = 0
a1100_biological_assets = 0
l2000_LIABILITIES = 0
l2010_AP = 0
l2020_Provisions = 0
l2030_other_liabilities = 0
l2040_current_taxes = 0
l2050_deferred_taxes = 0
c3000_EQUITY = 0
c3010_shares = 0
c3020_capital_reserves = 0
c3030_retained_earnings = 0
g4000_Capital_Gains = 0
g4010_gains = 0
g4020_losses = 0
i5000_REVENUES = 0
i5010_sales = 0
i5020_rent = 0
i5030_service = 0
i5040_other_revenue = 0
e6000_COGS = 0
e6010_inventory = 0
e6020_freight = 0
e6100_EXPENSES = 0
e6110_Ops_land = 0
e6120_Ops_labor_fixed = 0
e6130_Ops_labor_var = 0
e6140_Royalties = 0
e6150_Rents = 0
e6160_Debt_cost_Equity_int = 0
e6170_other_expenses = 0
e6200_Advertising = 0
e6210_Banking_fees = 0
e6220_Professional = 0
e6230_Licenses = 0
e6240_Telephone = 0
e6250_Utilities = 0
e6500_Taxes = 0
o7000_other_tracking = 0
o7010_EBITDA = 0
periods_per_year = 12

energy_production_annual = 44570000.  -- kWh/kW  or kWh annual energy output per rated kW
energy_output_cert_annual = 43288918. -- kWh/kW
forecast_peak_power = 2298.01 -- hours (was base_sys_perf)
annual_system_degredation = 0.005  -- % as decimal
system_power_output_peak = 19395. -- kW (was annu_sys_output)
sys_output_period = 0 -- kWh
production_begins = 24 -- period 24 is when production begins ie. period 1
period =  -1 * production_begins + 1 
year = floor( ( ( period - production_begins - 1 ) / periods_per_year ) ) 
next_year = year + 1
prev_year = year - 1

ppa_rate = .2 -- $/kWh
ppa_escalation = .025 -- % as decimal (factor)
power_revenue_period = 0 -- $  (was  direct_income)

equipment_costs = 107894187.0
capital_costs_installed = 117445809.11 -- $ (hard costs: equipment + fees)
other_costs = 10381571.06 -- $ (soft costs: shipping, construction/developer fees + insurance + operations during construction etc.)
system_cost_installed = capital_costs_installed + other_costs

capital_expense_payout_sched = acc_fin::list_set \".1 .1 .05 .06 .05 .05 .05 .2 .34\" ; --multiply this by system_cost_installed for dollar amounts
capital_expenses_begin = production_begins - 8 -- that is 23 - 8, given the 23 periods for construction prior to operation
direct_labor_expense_fixed_sched = acc_fin::list_set \"15166.67 15166.67 15166.667\" ;
direct_labor_expenses_begin = production_begins - 2
direct_labor_expense_var_sched = acc_fin::list_set \"0 0\" ; -- variable
direct_labor_expenses_var_begin = production_begins - 2
land_use_oper_cost_sched = acc_fin::list_set \"11385. 11385. 11385.\" ; -- operating costs
land_use_oper_cost_begin = production_begins - 2
commissions_pmnt_sched = acc_fin::list_set \"0 0\" ;
commissions_pmnt_begin = production_begins

loan_principal_initial = 0 -- $
loan_interest_rate_annual = .07 -- % as decimal, compounded each period
loan_interest_rate_period = loan_interest_rate_annual / periods_per_year
loan_apr = pow( 1 + loan_interest_rate_annual / periods_per_year , periods_per_year ) - 1 -- shown as a decimal
loan_years = 18
loan_payment = acc_fin::loan_payment loan_principal_initial loan_interest_rate_annual periods_per_year loan_years ;
period_loan_begins = 12 -- when loan funds become available
loan_limit = 60601000 -- $

equity_debt_balance = 0 -- should be about: 68404748.86 at period 0
equity_investment_initial = 30640000
equity_discount_rate_annual = .08 -- % as decimal, compounded each period
equity_discount_rate_period = equity_discount_rate_annual / periods_per_year
equity_as_loan_apr = pow( 1 + loan_interest_rate_annual / periods_per_year , periods_per_year ) - 1 -- shown as a decimal
period_equity_invest_begins = production_begins -- when the funds become available
equity_limit =  69900000 -- $

operations_rate_annual = 27.918 -- $/kW/yr
inflation_rate = .02252 -- % as decimal, annual
depreciation_annual = acc_fin::list_set \".6 .16 .096 .0576 .0576 .0288 0.\" ;
depreciation_basis = system_cost_installed * 0.85

tax_combined_rate = .4358 -- % expressed as decimal (state + federal)
incentive_us_itc = .3 * capital_costs_installed

flows_non_taxable_initial = 0 -- this should include any cost of debt of financing during construction, if pre-operation is not iterated in forecast
overage = 0 -- refers to overage of available cash via capital/finances

\#
-- constants --
forecast_peak_power = forecast_peak_power
system_power_output_peak = system_power_output_peak
annual_system_degredation = annual_system_degredation
ppa_rate = ppa_rate
ppa_escalation = ppa_escalation
operations_rate_annual = operations_rate_annual
inflation_rate = inflation_rate
tax_combined_rate = tax_combined_rate
system_cost_installed = system_cost_installed
periods_per_year = periods_per_year
depreciation_annual = depreciation_annual
depreciation_basis = depreciation_basis
loan_payment = loan_payment
loan_interest_rate_period = loan_interest_rate_period
loan_limit = loan_limit
period_loan_begins = period_loan_begins
equity_investment_initial = equity_investment_initial
incentive_us_itc = incentive_us_itc
equity_interest_rate_period = equity_interest_rate_period
equity_limit = equity_limit
loan_principal_initial = loan_principal_initial
period_equity_invest_begins = period_equity_invest_begins
production_begins = production_begins
capital_expenses_begin = capital_expenses_begin
direct_labor_expenses_begin = direct_labor_expenses_begin
direct_labor_var_expenses_begin = direct_labor_var_expenses_begin
land_use_oper_cost_begin = land_use_oper_cost_begin
commissions_pmnt_begin = commissions_pmnt_begin
capital_expense_payout_sched = capital_expense_payout_sched
direct_labor_expense_fixed_sched = direct_labor_expense_fixed_sched
direct_labor_expense_var_sched = direct_labor_expense_var_sched 
land_use_oper_cost_sched = land_use_oper_cost_sched
commissions_pmnt_sched = commissions_pmnt_sched

-- incremental --
period = period + 1 
year = floor( ( ( period.i +  periods_per_year - 1 ) / periods_per_year ) ) 
next_year = round( year.i + 1 )
prev_year = round( year.i - 1 )
producing = ( period.i > 0 )

-- iterative calculations --
Use these two equations if loans are dispersed at one time:
  -- equity_debt_balance equals equity_debt_balance + ( period_equity_invest_begins == i ) * equity_investment_initial 
  -- loan_balance equals loan_balance + ( period_loan_begins == i ) * loan_principal_initial


sys_output_period = acc_fin::energy_output forecast_peak_power system_power_output_peak annual_system_degredation year.i periods_per_year ; * producing
power_revenue_period = sys_output_period.i * ppa_rate * pow( 1 + ppa_escalation , prev_year.i ) 

income_taxable_period = power_revenue_period.i -- plus taxable incentives etc if any

capital_expense_ref = period.i - capital_expenses_begin
capital_expense = acc_fin::list_index capital_expense_payout_sched capital_expense_ref.i ; * system_cost_installed
direct_labor_expense_ref = period.i - direct_labor_expenses_begin
direct_labor_expense = acc_fin::list_index direct_labor_expense_fixed_sched direct_labor_expense_ref.i ;
direct_labor_expense_var_ref = period.i - direct_labor_var_expenses_begin
direct_labor_expense_var = acc_fin::list_index direct_labor_expense_var_sched direct_labor_expense_var_ref.i ;
land_use_oper_cost_ref = period.i - land_use_oper_cost_begin
land_use_oper_cost = acc_fin::list_index land_use_oper_cost_sched land_use_oper_cost_ref.i ;
commissions_pmnt_ref = period.i - commissions_pmnt_begin
commissions_pmnt = acc_fin::list_index commissions_pmnt_sched commissions_pmnt_ref.i ;
expense_operations = producing.i * operations_rate_annual * system_power_output_peak * pow( 1 + inflation_rate / periods_per_year , prev_year.i ) / periods_per_year 

free_cashflow_period = power_revenue_period.i - capital_expense.i - expense_operations.i - direct_labor_expense.i - direct_labor_expense_var.i - land_use_oper_cost.i - commissions_pmnt.i

The strategy for borrowing: first from financing, then from equity.  For modelling purposes, record excess borrowing as a debt_overage.  

debt_loan_available = loan_limit - loan_balance
abs_free_cashflow_period = abs( free_cashflow_period.i )  -- is cash required to offset debt when free_cashflow_period.i < 0
cash_required = abs_free_cashflow_period.i * ( free_cashflow_period.i < 0 )
debt_payout_needed_q = ( free_cashflow_period.i < 0 ) && ( debt_loan_available.i > 0 )
debt_payout_loan = debt_payout_needed_q.i * ( ( abs_free_cashflow_period.i  <= debt_loan_available.i ) * abs_free_cashflow_period.i + ( abs_free_cashflow_period.i > debt_loan_available.i ) * debt_loan_available.i )
loan_balance = loan_balance + debt_payout_loan.i

cash_required = cash_required.i - debt_payout_loan.i  -- remaining cash required
equity_debt_available = equity_limit - equity_debt_balance
equity_debt_payout_needed_q =  ( cash_required.i > 0 ) && ( equity_debt_available.i > 0 )
equity_debt_payout = equity_debt_payout_needed_q.i * ( ( cash_required.i <= equity_debt_available ) * cash_required.i + ( cash_required.i > equity_debt_available.i ) * equity_debt_available.i )
equity_debt_balance = equity_debt_balance + equity_debt_payout.i
cash_required = cash_required.i - equity_debt_payout.i

other_debt_payout_needed_q =  ( cash_required.i > 0 ) 
other_debt_payout = cash_required.i * other_debt_payout_needed_q.i
other_debt_balance = other_debt_balance + other_debt_payout.i
cash_required = 0 

expense_deductable_period = expense_operations.i -- inflows are positive, outflows negative
net_taxable = income_taxable_period.i - expense_deductable_period.i

depreciation_period = producing.i * acc_fin::list_index depreciation_annual year.i ; * depreciation_basis / periods_per_year
EBT_period = net_taxable.i - depreciation_period.i -- includes depreciation calculation
tax_period = ( EBT_period.i > 0 ) * EBT_period.i * tax_combined_rate
incentives_period = ( period.i == 1 ) * equity_investment_initial  + ( period.i == 3 ) * incentive_us_itc

-- loan payments do not happen when there is no cash to pay the loan
loan_payment_period = debt_payout_needed_q.i * ( loan_balance.i > loan_payment ) * loan_payment + ( loan_balance.i > 0 && loan_balance.i < loan_payment ) * loan_balance.i
loan_interest_period = loan_balance.i * loan_interest_rate_period


equity_interest_period = equity_debt_balance.i * equity_interest_rate_period
cost_of_finance_period = loan_interest_period * ( 1 - tax_combined_rate )
cost_of_equity_debt_period = equity_interest_period * ( 1 - tax_combined_rate )
cost_of_debt_period = cost_of_finance_period.i + cost_of_equity_debt_period.i


flows_non_taxable_period = cost_of_equity_debt_period.i + cost_of_debt_period.i  

net_cashflow_pre_tax = net_taxable.i + incentives_period.i + flows_non_taxable_period.i
net_cashflow_after_tax = net_cashflow_pre_tax.i - tax_period.i

loan_payment_principal_period = loan_payment_period.i - loan_interest_period.i
loan_payment_principal_period = f::max loan_payment_principal_period.i 0 ;

free_cashflow_available = net_cashflow_after_tax.i - loan_payment_principal_period.i -- after debt payment
free_cashflow_gt_equity_debt = ( free_cashflow_available.i > equity_debt_balance.i ) 
equity_payment_period = ( free_cashflow_gt_equity_debt.i == 0 ) * free_cashflow_available.i + ( free_cashflow_gt_equity_debt.i ) * equity_debt_balance.i

loan_balance = loan_balance.i - loan_payment_period.i + loan_interest_period.i 
equity_debt_balance = equity_debt_balance.i - equity_payment_period.i + equity_interest_period.i

\#
i period prev_year year next_year sys_output_period power_revenue_period capital_expense direct_labor_expense direct_labor_expense_var land_use_oper_cost commissions_pmnt expense_operations free_cashflow_period expense_deductable_period income_taxable_period net_taxable depreciation_period EBT_period tax_period incentives_period loan_payment_period equity_interest_period cost_of_finance_period cost_of_equity_debt_period cost_of_debt_period flows_non_taxable_period net_cashflow_pre_tax net_cashflow_after_tax debt_payout_loan loan_payment_principal_period loan_balance equity_debt_payout equity_payment_period equity_debt_balance other_debt_balance
\# 
sum_periods = f::sum \$i_list ;
sum_years = f::sum \$year_list ;
"

    }
}
    return $template
}

ad_proc -private acc_fin::model_compute { 
    model 
    {number_of_iterations "0"}
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
} {
    Returns a list of lists.
    First list element denotes how many errors there were.
    If number_of_iterations is greater than 0, Returns a list of lists, where each list element consists of a variable name and the values that it returns after each iteration, including the initial conditions. The report calculations return the variable name and the value returned from the function evaluation.
    If there are errors during compile, then subsequent list elements are the results of the model compile, useful for debugging purposes.

    Loop through model N (number) iterations, 0 iterations means pre-compile only (and check model for immediate errors).
    arg1, arg2, arg3 are passed to the model, a feature for adding variances to model computations, such as interval_duration and parameter ranges
    shorthand consists of these parts (with examples):
    section 1: initial calculations and conditions
     x = number
     y = number
    if this section begins with default = value, then all undeclared variables will automatically start with that value. 

    section 2: repeating calculations (in order calculated)

        y = i * 2 + 1
        z = pow( i , h ) * z
        for the above, the z refers automatically to the value from the previous iteration for consistency.
        to use current iteration value, append the variable with .i as in z.i  This only works if z.i has been defined ie there must be a "z = " statement before a statement with "= z.i"

    section 3: list of variables to report with iterations
        z y
    section 4: analysis calculations
       irr $y
    Each section is separated by a line with '\#'. Be sure to separate variables and operators etc by a space (or more). 
    reserved variables:
    i current iteration number, initial conditions are at iteraton 0, whole numbers
    h is i - 1
    timestamp(i) is timestamp associated with end of period in seconds from system epoch
    dt(i) is duration of a period between timestamp(i) - timestamp(h) in seconds
    
    An error in compilation returns the compiled model with error info.
} {

    # COMPILE model before executing. Do not bypass this as it includes security checks.
    #  calculates friendly list of lists from model represented in shorthand
    
    # we are combining the compile,compute and report functions to one function so that name space isn't confusing or buggy.
    ns_log Notice "acc_fin::model_compute compile starting"
    # split model by '#' into these parts:
    # 1. initial calculations and conditions (including number of iterations)
    # 2. repeating calculations
    # 3. items to report for each Nth iteration ( starting with iteration number M?)
    # 4. analysis calculations to report at end of iterations
    
    # then split each section into "lines" by CR
    
    # then split calculations by "=" (and add set,\[expr \])
    # output data as list of lists

    # for security, compiler should not allow square brackets, exec, source, or proc
    set _err_state 0
    set _err_text ""
    if { [regexp -nocase -- {[^a-z0-9_]exec[^a-z0-9_]} $model] } {
        incr _err_state
        append _err_text "Error: 'exec' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]upvar[^a-z0-9_]} $model] } {
        incr _err_state
        append _err_text "Error: 'upvar' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]uplevel[^a-z0-9_]} $model] } {
        incr _err_state
        append _err_text "Error: 'uplevel' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]proc[^a-z0-9_]} $model] } {
        incr _err_state 
        append _err_text "Error: 'proc' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[^a-z0-9_]source[^a-z0-9_]} $model] } {
        incr _err_state 
        append _err_text "Error: 'source' is not permitted in model definition. \n"
    }
    if { [regexp -nocase -- {[\]\[]} $model] } {
        incr _err_state 
        append _err_text "Error: 'square brackets' are not permitted in model definition. \n"
    }

    if { $_err_state == 0 } {
        # convert all internal variables to _variable_name to not get confused with model variables
        set _model $model
        set _number_of_iterations $number_of_iterations
        set _arguments [list $arg1 $arg2 $arg3]
        unset -nocomplain -- model number_of_iterations arg1 arg2 arg3

        set _section_count 0
        set _model_sections_list [split $_model \#]
        set _new_model_sections_list [list]
        foreach _model_section $_model_sections_list {
            incr _section_count
            
            if { $_section_count < 3 } {
                set _section_list [split $_model_section \n\r]
                set _new_section_list [list]
                foreach _calc_line $_section_list {
                    set comment_start [string first " --" $_calc_line]
                    if { $comment_start > 0 } {
                        set _calc_line [string range $_calc_line 0 $comment_start]
                    }
                    if { ![regsub -- {=} $_calc_line "\[expr \{ " _calc_line] } {
                        append _err_text "'${_calc_line}' ignored. No equal sign found.\n"
                        incr _err_state
                        set _calc_line ""
                    } else {
                        set _calc_line "set ${_calc_line} \} \]"
                        set _varname [string trim [string range ${_calc_line} 4 [string first expr $_calc_line]-2]]
                        regsub {[ ][ ]+} $_calc_line { } _calc_line
                        lappend _new_section_list $_calc_line
                        if { ![info exists ${_varname}_list] } {
                            # create list and array history for each variable for logging values of each iteration (for post run analysis etc.)
                            set ${_varname}_list [list]
                            array set ${_varname}_arr [list]
                        }
                    }
                }
                set _section_list $_new_section_list
            }
            if { $_section_count eq 1 } {
                set _new_section_list [list]
                foreach _calc_line $_section_list {
                    set comment_start [string first " --" $_calc_line]
                    if { $comment_start > 0 } {
                        set _calc_line [string range $_calc_line 0 $comment_start]
                    }
                    # substitute var_arr(0) for variables on left side
                    set _varname [string trim [string range ${_calc_line} 4 [string first expr $_calc_line]-2]]
                    regsub -- $_varname $_calc_line "${_varname}_arr(0)" _calc_line
                    # and on right side
                    regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[ ]} $_calc_line { $\1_arr(0) } _calc_line
                    # do this twice to catch stragglers since spaces may be delimiters for both sides
                    regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[ ]} $_calc_line { $\1_arr(0) } _calc_line
                    regsub -nocase -all -- { acc_fin::([a-z])} $_calc_line { [acc_fin::\1} _calc_line
                    regsub -nocase -all -- { ;} $_calc_line { ] } _calc_line
                    regsub -all -- { qaf_([a-z])} $_calc_line { [qaf_\1} _calc_line
                    regsub -all -- { f::} $_calc_line { [f::} _calc_line
                    # make all numbers double precision
                    regsub -nocase -all -- {[ ]([0-9]+)[ ]} $_calc_line { \1. } _calc_line

                    # initial period is period 0
                    if { [string length $_calc_line ] > 0 } { 
                        regsub {[ ][ ]+} $_calc_line { } _calc_line
                        lappend _new_section_list $_calc_line
                    }
                }
                set _section_list $_new_section_list
            }


            if { $_section_count eq 2 } {

                set _new_section_list [list]
                foreach _calc_line $_section_list {
                    set comment_start [string first " --" $_calc_line]
                    if { $comment_start > 0 } {
                        set _calc_line [string range $_calc_line 0 $comment_start]
                    }

                    # substitute var_arr($_i) for variables on left side
                    set _original_calc_line $_calc_line
                    set _varname [string trim [string range ${_calc_line} 4 [string first expr $_calc_line]-2]]
                    if { [catch {
                        regsub -- $_varname $_calc_line "${_varname}_arr(\$_i)" _calc_line 
                        # substitute var_arr($_h) for variables on right side
                        # for each string found not an array or within paraenthesis, 
                        regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[ ]} $_calc_line { $\1_arr($_h) } _calc_line
                        # do this twice to catch stragglers since spaces may be delimiters for both sides
                        regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[ ]} $_calc_line { $\1_arr($_h) } _calc_line
                        regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[\.][i][ ]} $_calc_line { $\1_arr($_i) } _calc_line
                        regsub -nocase -all -- { acc_fin::([a-z])} $_calc_line { [acc_fin::\1} _calc_line
                        regsub -nocase -all -- { ;} $_calc_line { ] } _calc_line
                        regsub -all -- { qaf_([a-z])} $_calc_line { [qaf_\1} _calc_line
                        regsub -all -- { f::} $_calc_line { [f::} _calc_line
                        # make all numbers double precision
                        regsub -nocase -all -- {[ ]([0-9]+)[ ]} $_calc_line { \1. } _calc_line
                        } _error_text]} {
                            lappend _err_text "ERROR compiling line: ${_original_calc_line} MESSAGE: ${_error_text}"
                            incr _err_state
                        }
                    if { [string length $_calc_line ] > 0 } { 
                        regsub {[ ][ ]+} $_calc_line { } _calc_line
                        lappend _new_section_list $_calc_line
                    }
                }
                set _section_list $_new_section_list
            }

            if { $_section_count eq 3 } {
                set _section_list [split $_model_section \n\r\ \,]
                set _new_section_list [list]
                set _variables_list [list]
                # report values 
                # convert to list of variables that get converted into a list of lists.
                # to be processed externally (sorted etc)
                foreach _named_var $_section_list {
                    set _named_var_trimmed [string trim $_named_var]
                    if { [string length $_named_var_trimmed] > 0 } {
                        lappend _variables_list $_named_var_trimmed
                    }
                    set _new_section_list $_variables_list
                    set _section_list $_new_section_list
                }
            }
            
            if { $_section_count eq 4 } {
                set _section_list [split $_model_section \n\r]
                set _new_section_list [list]
                foreach _calc_line $_section_list {
                    if { ![regsub -- {=} $_calc_line "\[expr \{ " _calc_line] } {
                        append _err_text "'${_calc_line}' ignored. No equal sign found.\n"
                        incr _err_state
                        set _calc_line ""
                    } else {
                        set _calc_line "set ${_calc_line} \} \]"
                        regsub -all -- { f::} $_calc_line { [f::} _calc_line
                        regsub -all -- { acc_fin::([a-z])} $_calc_line { [acc_fin::\1} _calc_line
                        regsub -all -- { qaf_([a-z])} $_calc_line { [qaf_\1} _calc_line
                        regsub -all -- { ;} $_calc_line { ] } _calc_line
                        regsub {[ ][ ]+} $_calc_line { } _calc_line
                        lappend _new_section_list $_calc_line
                    }
                }
                set _section_list $_new_section_list
            }
            lappend _new_model_sections_list $_section_list
                } 
                set _model_sections_list $_new_model_sections_list
            } else {
                set _output [linsert $_model_sections_list 0 [list "ERRORS: ${_err_text}" ${_err_state}] ]
                ns_log Notice "acc_fin::model_compute compile end --with errors"
                return $_output
            }

#compute $_model_sections_list
    # 0 iterations = compile only, do not compute
    if { $_number_of_iterations == 0 } {
        ns_log Notice "acc_fin::model_compute compile end"
        set _output [linsert $_model_sections_list 0 [list "ERRORS" $_err_state]]
        return $_output
    }

    # set initital conditions
    set _model0 [lindex $_model_sections_list 0]
    foreach _line $_model0 {
         eval $_line
    }

    set _model1 [lindex $_model_sections_list 1]
    # If default_arr(0) exists and {var}_arr(0) does not exist, set {var}_arr(0) to $default_arr(0)
    # this is a quick way to set a default value for all variables  instead of explicitly naming all of the variables.

    # if $_default is defined, step through variables, set _any unset variables to $default
    if { [info exists default_arr(0) ] } {
        set _dependent_var_fragment_list [split $_model1 {\(} ]
        foreach _section_fragment $_dependent_var_fragment_list {
            if { [regexp -nocase -- {[\$ ]([a-z][a-z0-9_]+)[_][a][r][r]$} $_section_fragment _scratch _dependent_variable] } {

                if { ![info exists ${_dependent_variable}_arr(0) ] } {
                    set ${_dependent_variable}_arr(0) $default_arr(0)
                }
            }
        }
    }
        
    # initial conditions
    set timestamp [clock seconds]
    set timestamp_arr(0) $timestamp
    set h_arr(0) -1.
    set i_arr(0) 0.
 
    # iteration conditions
    set h 0.
    set _h 0
    for {set _i 1} {$_i <= $_number_of_iterations} {incr _i} {
        # other values are set in the model automatically
        set h_arr($_i) $h
        set i [expr { double($_i) } ]
        set i_arr($_i) $i


        foreach _line $_model1 {
            eval $_line
        }
        # timestamp for $_i is after $_i iteration is done.
        set timestamp_arr($_i) [clock seconds]
        set dt_arr($_i) [expr { $timestamp_arr($_i) - $timestamp_arr($_h) } ]
        set _h $_i
        set h $i
    }


    # make ordered lists of each of the different arrays (by index), for each of the variables that are being reported
    # So, {var}_arr(0..n) becomes {var}_list
    set _model2 [lindex $_model_sections_list 2]
    for {set _i 0} {$_i <= $_number_of_iterations} {incr _i} {
        foreach _variable_name $_model2 {
            lappend ${_variable_name}_list [set ${_variable_name}_arr($_i)]
        }
    }
    set _output [list]
    foreach _variable_name $_model2 {
        lappend _output [linsert [set ${_variable_name}_list] 0 $_variable_name]
    }


    # report calculations
    set _model3 [lindex $_model_sections_list 3]
    
    foreach _line $_model3 {
        set _varname [string trim [string range ${_line} 4 [string first " " ${_line} 4]]]
        set _calc_value [eval $_line]
        lappend _output [list $_varname $_calc_value]
    }

        ns_log Notice "acc_fin::model_compute end"
        set _output [linsert $_output 0 [list "ERRORS" 0]]
    return $_output

}

 

ad_proc -private acc_fin::gl_array_create {
    array_name
    {gl_type "capbug"}
} {
    creates an array of general ledger (and supporting arrays) with some predefined accounts, with default values of 0.
gl_type choices are:
    "capbug" for capital budgeting (project/program forecasting)
    "general" for general accounts ledger
    "mfg" for manufacturing based GL
    "service" for service based GL
} {
    upvar $array_name gl
    upvar ${array_name}_title gl_title
    upvar ${array_name}_element gl_element
    upvar ${array_name}_nature gl_nature
    # a predefined list of accounts. account number is acc_ref 
    # gl_sorted(sort_key) account number. This allows quick iterating in sorted order.
    # 
    # gl_title(acc_ref) for pretty names, 
    # gl_element(acc_ref) for group type, example: asset, liability, income, expense, capital; see http://en.wikipedia.org/wiki/General_ledger 
    # gl_nature(acc_ref) for type, example: real,entity,nominal; see http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system
    switch -exact -- $gl_type {
        capbug {
            array set gl_title {
1000 "ASSETS"
1010 "Cash"
1020 "Inventories"
1030 "Accounts Receivables"
1040 "Prepaid expenses"
1050 "Property, plan and equipment"
1060 "Real estate"
1070 "Intangible assets"
1080 "other financial assets"
1090 "equity investments"
1100 "biological assets (living)"
2000 "LIABILITIES"
2010 "Accounts payables"
2020 "Provisions for warranties etc"
2030 "other liabilities"
2040 "current taxes"
2050 "deferred taxes"
3000 "EQUITY"
3010 "shares"
3020 "capital reserves"
3030 "retained earnings"
4000 "Capital Gains / Losses"
4010 "gains"
4020 "losses"
5000 "REVENUES"
5010 "sales"
5020 "rent"
5030 "service"
5040 "other revenue"
6000 "COGS"
6010 "inventory"
6020 "freight"
6100 "EXPENSES"
6110 "Operating costs, land use"
6120 "Operating costs, direct labor, fixed"
6130 "Operating costs, direct labor, variable"
6140 "Royalties, commissions"
6150 "Rents"
6160 "Cost of debt + equity interest"
6170 "other expenses"
6200 "Advertising"
6210 "Banking fees"
6220 "Professional services"
6230 "Licenses"
6240 "Telephone"
6250 "Utilities"
6500 "Taxes"
7000 "other tracking"
7010 "EBITDA"
            }
    array set element_arr {
1 asset
2 liability
3 capital
4 gains
5 income
6 expense
7 report
    }
    array set nature_arr {
1 real
2 personal
3 real
4 nominal
5 nominal
6 nominal
7 nominal
    }
    foreach account [array names gl_title] {
        set element [string index $account 0]
        set gl_element($account) $element_arr($element)
        set gl_nature($account) $nature_arr($element)
        set gl_sorted($account) $account
    }

}
        }

        general {
            array set gl {
1000  "CURRENT ASSETS"
1060  "Checking Account"
1065  "Petty Cash"
1200  "Accounts Receivables"
1205  "Allowance for doubtful accounts"
1500  "INVENTORY ASSETS"
1510  "Inventory"
1520  "Inventory / General"
1530  "Inventory / Aftermarket Parts"
1800  "CAPITAL ASSETS"
1820  "Office Furniture &amp; Equipment"
1825  "Accum. Amort. -Furn. &amp; Equip."
1840  "Vehicle"
1845  "Accum. Amort. -Vehicle"
2000  "CURRENT LIABILITIES"
2100  "Accounts Payable"
2110  "Accrued Income Tax - Federal"
2120  "Accrued Income Tax - State"
2130  "Accrued Franchise Tax"
2140  "Accrued Real &amp; Personal Prop Tax"
2150  "Sales Tax"
2160  "Accrued Use Tax Payable"
2160  "Corporate Taxes Payable"
2190  "Federal Income Tax Payable"
2210  "Accrued Wages"
2212  "Workers Comp Payable"
2220  "Accrued Comp Time"
2240  "Accrued Vacation Pay"
2250  "Pension Plan Payable"
2260  "Employment Insurance Payable"
2280  "Payroll Taxes Payable"
2310  "Accr. Benefits - 401K"
2390  "VAT (10%)"
2320  "Accr. Benefits - Stock Purchase"
2395  "VAT (14%)"
2330  "Accr. Benefits - Med, Den"
2400  "VAT (30%)"
2340  "Accr. Benefits - Payroll Taxes"
2350  "Accr. Benefits - Credit Union"
2360  "Accr. Benefits - Savings Bond"
2370  "Accr. Benefits - Garnish"
2380  "Accr. Benefits - Charity Cont."
2600  "LONG TERM LIABILITIES"
2620  "Bank Loans"
2680  "Loans from Shareholders"
3300  "SHARE CAPITAL"
3350  "Common Shares"
3500  "RETAINED EARNINGS"
3590  "Retained Earnings - prior years"
4000  "SALES REVENUE"
4010  "Sales"
4020  "Sales / General"
4030  "Sales / Aftermarket Parts"
4300  "CONSULTING REVENUE"
4320  "Consulting"
4400  "OTHER REVENUE"
4430  "Shipping &amp; Handling"
4440  "Interest"
4450  "Foreign Exchange Gain"
5000  "COST OF GOODS SOLD"
5010  "Purchases"
5020  "COGS / General"
5030  "COGS / Aftermarket Parts"
5100  "Freight"
5400  "PAYROLL EXPENSES"
5410  "Wages &amp; Salaries"
5420  "Employment Insurance Expense"
5424  "Wages - Overtime"
5430  "Benefits - Comp Time"
5434  "Pension Plan Expense"
5440  "Benefits - Payroll Taxes"
5444  "Workers Comp Expense"
5450  "Benefits - Workers Comp"
5460  "Benefits - Pension"
5470  "Benefits - General Benefits"
5474  "Employee Benefits"
5510  "Inc Tax Exp - Federal"
5520  "Inc Tax Exp - State"
5530  "Taxes - Real Estate"
5540  "Taxes - Personal Property"
5550  "Taxes - Franchise"
5560  "Taxes - Foreign Withholding"
5600  "GENERAL &amp; ADMINISTRATIVE EXPENSES"
5610  "Accounting &amp; Legal"
5615  "Advertising &amp; Promotions"
5620  "Bad Debts"
5650  "Capital Cost Allowance Expense"
5660  "Amortization Expense"
5680  "Income Taxes"
5685  "Insurance"
5690  "Interest &amp; Bank Charges"
5700  "Office Supplies"
5760  "Rent"
5765  "Repair &amp; Maintenance"
5780  "Telephone"
5785  "Travel &amp; Entertainment"
5790  "Utilities"
5795  "Registrations"
5800  "Licenses"
5810  "Foreign Exchange Loss"
        }
    }
mfg {
    array set gl {
1000  "CURRENT ASSETS"
1060  "Checking Account"
1065  "Petty Cash"
1200  "Accounts Receivables"
1205  "Allowance for doubtful accounts"
1500  "INVENTORY ASSETS"
1520  "Inventory / General"
1530  "Inventory / Raw Materials"
1540  "Inventory / Work in process"
1550  "Inventory / Finished Goods"
1800  "CAPITAL ASSETS"
1820  "Office Furniture &amp; Equipment"
1825  "Accum. Amort. -Furn. &amp; Equip."
1840  "Vehicle"
1845  "Accum. Amort. -Vehicle"
2000  "CURRENT LIABILITIES"
2100  "Accounts Payable"
2600  "LONG TERM LIABILITIES"
2620  "Bank Loans"
2680  "Loans from Shareholders"
3300  "SHARE CAPITAL"
3350  "Common Shares"
3500  "RETAINED EARNINGS"
3590  "Retained Earnings - prior years"
4000  "SALES REVENUE"
4020  "Sales / General"
4030  "Sales / Manufactured Goods"
4040  "Sales / Aftermarket Parts"
4400  "OTHER REVENUE"
4430  "Shipping &amp; Handling"
4440  "Interest"
4450  "Foreign Exchange Gain"
5000  "COST OF GOODS SOLD"
5010  "Purchases"
5020  "COGS / General"
5030  "COGS / Raw Materials"
5040  "COGS / Direct Labor"
5050  "COGS / Overhead"
5100  "Freight"
5400  "PAYROLL EXPENSES"
5410  "Wages &amp; Salaries"
5600  "GENERAL &amp; ADMINISTRATIVE EXPENSES"
5610  "Accounting &amp; Legal"
5615  "Advertising &amp; Promotions"
5620  "Bad Debts"
5660  "Amortization Expense"
5685  "Insurance"
5690  "Interest &amp; Bank Charges"
5700  "Office Supplies"
5760  "Rent"
5765  "Repair &amp; Maintenance"
5780  "Telephone"
5785  "Travel &amp; Entertainment"
5790  "Utilities"
5795  "Registrations"
5800  "Licenses"
5810  "Foreign Exchange Loss"
2110  "Accrued Income Tax - Federal"
2120  "Accrued Income Tax - State"
2130  "Accrued Franchise Tax"
2140  "Accrued Real &amp; Personal Prop Tax"
2150  "Sales Tax"
2210  "Accrued Wages"
5510  "Inc Tax Exp - Federal"
5520  "Inc Tax Exp - State"
5530  "Taxes - Real Estate"
5540  "Taxes - Personal Property"
5550  "Taxes - Franchise"
5560  "Taxes - Foreign Withholding"
    }
} 
  service {
      array set gl {
1000  "CURRENT ASSETS"
1060  "Checking Account"
1065  "Petty Cash"
1200  "Accounts Receivables"
1205  "Allowance for doubtful accounts"
1500  "INVENTORY ASSETS"
1520  "Inventory"
1800  "CAPITAL ASSETS"
1820  "Office Furniture &amp; Equipment"
1825  "Accum. Amort. -Furn. &amp; Equip."
1840  "Vehicle"
1845  "Accum. Amort. -Vehicle"
2000  "CURRENT LIABILITIES"
2100  "Accounts Payable"
2600  "LONG TERM LIABILITIES"
2620  "Bank Loans"
2680  "Loans from Shareholders"
3300  "SHARE CAPITAL"
3350  "Common Shares"
3500  "RETAINED EARNINGS"
3590  "Retained Earnings - prior years"
4000  "CONSULTING REVENUE"
4020  "Consulting"
4400  "OTHER REVENUE"
4410  "General Sales"
4440  "Interest"
4450  "Foreign Exchange Gain"
5000  "EXPENSES"
5020  "Purchases"
5400  "PAYROLL EXPENSES"
5410  "Wages &amp; Salaries"
5600  "GENERAL &amp; ADMINISTRATIVE EXPENSES"
5610  "Accounting &amp; Legal"
5615  "Advertising &amp; Promotions"
5620  "Bad Debts"
5660  "Amortization Expense"
5685  "Insurance"
5690  "Interest &amp; Bank Charges"
5700  "Office Supplies"
5760  "Rent"
5765  "Repair &amp; Maintenance"
5780  "Telephone"
5785  "Travel &amp; Entertainment"
5790  "Utilities"
5795  "Registrations"
5800  "Licenses"
5810  "Foreign Exchange Loss"
2110  "Accrued Income Tax - Federal"
2120  "Accrued Income Tax - State"
2130  "Accrued Franchise Tax"
2140  "Accrued Real &amp; Personal Prop Tax"
2150  "Sales Tax"
2210  "Accrued Wages"
5510  "Inc Tax Exp - Federal"
5520  "Inc Tax Exp - State"
5530  "Taxes - Real Estate"
5540  "Taxes - Personal Property"
5550  "Taxes - Franchise"
5560  "Taxes - Foreign Withholding"
      }
  }
}



ad_proc -private acc_fin::gl_tx_balanced {
    transaction_list 
} {
    Returns 1 for True, or 0 for False to Question: Is supplied GL transaction balanced?
    transaction_list is a list  of list pairs {account_number amount}
    checks total sum, not the relevance of a particular account to it's placement in the accounting equation.
} {
    set sum 0.
    set errors 0
    foreach list_pair $transaction_list {
        set term [lindex $list_pair 1]
        if { [ad_var_type_check_number_p $term] } {
            set sum [expr { $sum + $term } ]
        } else {
            set errors 1
        }
        set balanced [expr { $sum == 0. && $errors == 0 } ]
        return $balanced
    }
}

ad_proc -private acc_fin::gl_tx {
    general_ledger_array_name
    transaction_actnbr_amount_pairs_list
} {
    processes a GL transaction of multiple columns 
} {
    upvar $general_ledger_array_name gl
    set success [acc_fin::gl_tx_balanced $transaction_actnbr_amount_pairs_list]
    if { $success } {
        foreach tx_pair $transaction_actnbr_amount_pairs_list {
            set account [lindex $tx_pair 0]
            set amount [lindex $tx_pair 1]
            if { [info exists gl($account) ] } {
                set gl($account) [expr { $gl($account) + $amount } ]
            } else {
                set gl($account) $amount
            }
        }
    }
    return $success
}



# system energy output 
# revenue from energy output

# create procs to maintain a debt via interation (add interest, add payment, adjust balance for each)
# monitor for payback period during iteration
# 
# create proce that shows balance sheet etc for any period or difference between two or more periods
# proc profitability_index (PV of future cashflows over project life / initial investment)


