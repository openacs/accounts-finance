# /packages/accounts-finance/tcl/test/finance-test-procs.tcl
ad_library {
    Test procs for finance calculations
    @creation-date 2010-05-20
    @cvs-id $Id:
}
aa_register_case -cats { 
    api
} finance_basics {
    Test acc_fin:: list functions
} {
    aa_run_with_teardown -rollback -test_code {
        # numbers from http://en.wikipedia.org/wiki/Modified_internal_rate_of_return
        set cashflow1 [list -1000 -4000 5000 2000]
        set cashflow2 [list -1000 -4000]
        set cashflow3 [list 5000 2000]
        set finance_rate 0.1
        set reinvest_rate 0.12
        set discount_rate 0.2548
        aa_equals "Checp PV" [acc_fin::pv $cashflow2 $finance_rate] -4636.36
        aa_equals "Check FV simple interest" [acc_fin::fvsimple $cashflow3 $reinvest_rate] 7600.
        aa_equals "Check NPV" [acc_fin::npv $cashflow1 $discount_rate] 0.
        aa_equals "Check IRR" [acc_fin::irr $cashflow1] $discount_rate
        aa_equals "Check MIRR" [acc_fin::mirr $cashflow1 $finance_rate $reinvest_rate] "0.1791"
    }
}
