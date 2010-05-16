ad_library {

    routines used for modeling cashflows etc
    @creation-date 16 May 2010
    @cvs-id $Id:
}

namespace eval acc_fin {}

ad_proc -private qaf_process_model { model } {
     returns calculation friendly list of lists from model represented in shorthand
    shorthand consists of these parts:
section 1: initial calculations and conditions
section 2: repeating calculations (in order calculated)
section 3: list of variables to report with each iteration
  Each section is separated by a line with '\#'.
} {
  # split model by '#' into these parts:
  # 1. initial calculations and conditions (including number of iterations)
  # 2. repeating calculations
  # 3. items to report after X iterations starting with iteration number Y
  # 4. additional items to report at end of iterations

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
        foreach model_section $model_sections_list {
            incr section_count
        
            
            if { $section_count < 3 } {
                set section_list [split $model_section \n\r]
                foreach calc_line $section_list {
                    if { ![regsub -- {=} $calc_line {} calc_line] } {
                        append err_text "'${calc_line}' ignored. No equal sign found.\n"
                        incr err_state
                        set $calc_line ""
                    }
                    set calc_line "set ${calc_line}"
                }
                if { $section_count eq 3 } {
                    set section_list [split $model_section \n\r\ \,]
                    set variables_list [list]
                    # report values 
                    # convert to list of variables that get converted into a list of lists.
                    # to be processed externally (sorted etc)
                    foreach named_var $section_list {
                        set named_var [trim $named_var]
                        if { [string length $named_var] > 0 } {
                            lappend variables_list $named_var
                        }
                    }
                } 
                
            }
                
        } 

    } else {
        set output "Unable to compile model. ${err_state} Errors. \n ${err_text}"
        return $output

    }




}
