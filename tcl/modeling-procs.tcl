ad_library {

    routines used for modeling cashflows etc
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}

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
annual_system_degredation = 0.005  -- percent as decimal
system_power_output_peak = 19395. -- kW
sys_output_period = 0 -- kWh

ppa_rate = .2 -- $/kWh
ppa_escalation = .025 -- percent as decimal (factor)
power_revenue_period = 0 -- $  (was  direct_income)


\#
period = i + 1
periods_per_year = periods_per_year
year = int( ( ( i +  periods_per_year ) / periods_per_year ) ) 
next_year = year.i + 1
prev_year = year.i - 1

sys_output_period = acc_fin::energy_output forecast_peak_power system_power_output_peak annual_system_degredation year.i periods_per_year ; 
power_revenue_period = sys_output_period.i * ppa_rate * pow( 1 + ppa_escalation , prev_year.i )

forecast_peak_power = forecast_peak_power
system_power_output_peak = system_power_output_peak
annual_system_degredation = annual_system_degredation
ppa_rate = ppa_rate
ppa_escalation = ppa_escalation
\#
i period next_year year sys_output_period power_revenue_period
\# 
sum_periods = f::sum \$i_list ;
sum_years = f::sum \$year_list ;
sum_next_years = f::sum \$next_year_list ;
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
                    if { ![regsub -- {=} $_calc_line "\[expr \{ " _calc_line] } {
                        append _err_text "'${_calc_line}' ignored. No equal sign found.\n"
                        incr _err_state
                        set _calc_line ""
                    } else {
                        set comment_start [string first " --" $_calc_line]
                        if { $comment_start > 0 } {
                            set _calc_line [string range $_calc_line 0 $comment_start]
                        }
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
                    # substitute var_arr(0) for variables on left side
                    set _varname [string trim [string range ${_calc_line} 4 [string first expr $_calc_line]-2]]
                    regsub -- $_varname $_calc_line "${_varname}_arr(0)" _calc_line
                    # and on right side
                    regsub -nocase -all -- {[ ]([a-z][a-z0-9_]*)[ ]} $_calc_line { $\1_arr(0) } _calc_line
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
                    # substitute var_arr($_i) for variables on left side
                    set _varname [string trim [string range ${_calc_line} 4 [string first expr $_calc_line]-2]]
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

                    # make all numbers double precision
                    regsub -nocase -all -- {[ ]([0-9]+)[ ]} $_calc_line { \1. } _calc_line

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
        #  compiled model as list of lists

    } else {
        set _output [linsert $_model_sections_list 0 [list "ERRORS: ${_err_text}" ${_err_state}] ]
        ns_log Notice "acc_fin::model_compute compile end --with errors"
        return $_output
    }

#compute $_model_sections_list
    # 0 iterations = compile only, do not compute
    if { $_number_of_iterations == 0 } {
        ns_log Notice "acc_fin::model_compute compile end"
        set _output [linsert $_model_sections_list 0 [list "ERRORS" 0]]
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


