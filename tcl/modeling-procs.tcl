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
    set sign [expr { $number / double( abs ( $number ) ) } ]
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
period = 0
periods_per_year = 12
total_periods = 20
#
period = i
year = int( ( period + ( periods_per_year - 1 ) / periods_per_year ) )
#
i period year periods_per_year total_periods
"

    }
}
    return $template
}

ad_proc -private acc_fin::model_compile { 
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
                        # create list and array history for each variable for logging values of each iteration (for post run analysis etc.)
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

ad_proc -private acc_fin::model_compute { 
    model 
    {number}
    {arg1}
    {arg2}
    {arg3}
} {
    Loop through model N (number) iterations.
    arg1, arg2, arg3 are passed to the model, a feature for adding variances to model computations, such as interval_duration and parameter ranges
} {
    # given: variable default for iteration 0: default_arr(0) 
    #  a variable supplied by user is {var}
    # each {var} gets a {var}_arr($i) and {var}_list which log values through iterations ($i).
    # If default_arr(0) exists and {var}_arr(0) does not exist, set {var}_arr(0) to $default_arr(0)
    # this is a quick way to set a default value for all variables  instead of explicitly naming all of the variables.

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



# create procs for?
# AR/
# AR/sale  1000 x, 1200 -x, 1200 x, 4000 x
# AP/vendor payment cash  1000 -x ,2100 x, 2100 -x, 5000 x
# ..let's wait until we know if this is necessary. gl_tx seems adequate for now.

# system energy output 
# revenue from energy output

# create procs to maintain a debt via interation (add interest, add payment, adjust balance for each)
# monitor for payback period during iteration
# 
# create proce that shows balance sheet etc for any period or difference between two or more periods
# proc profitability_index (PV of future cashflows over project life / initial investment)


