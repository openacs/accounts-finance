set title "PRETTI Example 2"
set context [list [list index "Documentation"] $title]

set p1_html "<pre>"
set p1_list [acc_fin::example_table p10b]
foreach row $p1_list {
    append p1_html [join $row "," ]
    append p1_html "\n"
}
append p1_html "</pre>"

set p2_html "<pre>"
set p2_list [lindex [acc_fin::example_table p20b]]
append p2_html [lindex $p2_list 2]
append p2_html "</pre>"
set subtitle_html [lindex $p2_list 0]
set comments_html [lindex $p2_list 1]
regsub -all -- { ([h][t][t][p][s]?[:][\/][\/][A-Za-z0-9\.\:\-\/\_]+)} $comments_html { <a href="\1">\1</a> } comments_html

set p3_html "<p>* not used<p>"

set p1b_html {<pre>name: WikipediaPERTchartScenario
    tid: 10122
  </pre>

  <table border="1" cellpadding="3" cellspacing="0">
<tr><td>name</td><td>value</td></tr>
<tr><td>activity_table_name</td><td>WikipediaPERTchart</td></tr>
</table>}

set p4_html { <h3>WikipediaPERTchart scenario.p4 t=0.5 c=0.5</h3>

  

  <pre>name: WikipediaPERTchartScenario.p4t0.5c0.5
    tid: 10126
  </pre>

  <h3>Computation report</h3><table>
<tr><td>path_1</td><td>path_2</td><td>path_3</td></tr>
    <tr><td style="vertical-align: top; background-color: #f7f77f;">10 <br>  t:0.0 <br> tw:0.0 <br> tn:0.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:1.0 <br> cn:1.0 <br> d:() <br> <!-- 1 3 --> </td><td style="vertical-align: top; background-color: #f7f77f;">10 <br>  t:0.0 <br> tw:0.0 <br> tn:0.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:1.0 <br> cn:1.0 <br> d:() <br> <!-- 1 3 --> </td><td style="vertical-align: top; background-color: #f7f77f;">10 <br>  t:0.0 <br> tw:0.0 <br> tn:0.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:1.0 <br> cn:1.0 <br> d:() <br> <!-- 1 3 --> </td></tr>
    <tr><td style="vertical-align: top; background-color: #ffff7f;">A <br>  t:3.0 <br> tw:3.0 <br> tn:3.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:2.0 <br> cn:2.0 <br> d:(10) <br> <!-- 0 2 --> </td><td style="vertical-align: top; background-color: #137f13; color: #ffffff;">B <br>  t:4.0 <br> tw:4.0 <br> tn:4.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:2.0 <br> cn:2.0 <br> d:(10) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #ffff7f;">A <br>  t:3.0 <br> tw:3.0 <br> tn:3.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:2.0 <br> cn:2.0 <br> d:(10) <br> <!-- 0 2 --> </td></tr>
    <tr><td style="vertical-align: top; background-color: #f7f77f;">30 <br>  t:0.0 <br> tw:3.0 <br> tn:3.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:3.0 <br> cn:3.0 <br> d:(A) <br> <!-- 0 2 --> </td><td style="vertical-align: top; background-color: #0b7f0b; color: #ffffff;">20 <br>  t:0.0 <br> tw:4.0 <br> tn:4.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:3.0 <br> cn:3.0 <br> d:(B) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #f7f77f;">30 <br>  t:0.0 <br> tw:3.0 <br> tn:3.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:3.0 <br> cn:3.0 <br> d:(A) <br> <!-- 0 2 --> </td></tr>
    <tr><td style="vertical-align: top; background-color: #ffff7f;">D <br>  t:1.0 <br> tw:4.0 <br> tn:4.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:4.0 <br> cn:4.0 <br> d:(30) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #137f13; color: #ffffff;">C <br>  t:3.0 <br> tw:7.0 <br> tn:7.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:4.0 <br> cn:4.0 <br> d:(20) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #137f13; color: #ffffff;">E <br>  t:3.0 <br> tw:6.0 <br> tn:6.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:4.0 <br> cn:4.0 <br> d:(30) <br> <!-- 0 1 --> </td></tr>
    <tr><td style="vertical-align: top; background-color: #f7f77f;">40 <br>  t:0.0 <br> tw:4.0 <br> tn:4.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:5.0 <br> cn:5.0 <br> d:(D) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #f7f77f;">50 <br>  t:0.0 <br> tw:7.0 <br> tn:7.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:5.0 <br> cn:15.0 <br> d:(F E C) <br> <!-- 1 3 --> </td><td style="vertical-align: top; background-color: #f7f77f;">50 <br>  t:0.0 <br> tw:6.0 <br> tn:7.0 <br> fw:1.0 <br> &nbsp;c:1.0 <br> cw:5.0 <br> cn:15.0 <br> d:(F E C) <br> <!-- 1 3 --> </td></tr>
    <tr><td style="vertical-align: top; background-color: #ffff7f;">F <br>  t:3.0 <br> tw:7.0 <br> tn:7.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:6.0 <br> cn:6.0 <br> d:(40) <br> <!-- 0 1 --> </td><td style="vertical-align: top; background-color: #4f4f4f; color: #ffffff;">&nbsp;</td><td style="vertical-align: top; background-color: #4f4f4f; color: #ffffff;">&nbsp;</td></tr>
    <tr><td style="vertical-align: top; background-color: #f7f77f;">50 <br>  t:0.0 <br> tw:7.0 <br> tn:7.0 <br> fw:0.0 <br> &nbsp;c:1.0 <br> cw:7.0 <br> cn:15.0 <br> d:(F E C) <br> <!-- 1 3 --> </td><td style="vertical-align: top; background-color: #4f4f4f; color: #ffffff;">&nbsp;</td><td style="vertical-align: top; background-color: #4f4f4f; color: #ffffff;">&nbsp;</td></tr>
</table>


  <p>
    Scenario report for WikipediaPERTchart scenario: scenario_name WikipediaPERTchartScenario , cp_duration_at_pm 7.0 , cp_cost_pm 7.0 , max_act_count_per_track 7 , time_probability_point 0.5 , cost_probability_point 0.5 , setup_time 0 , main_processing_time 0 seconds , time/date finished processing 2014 Sep 27 22:47:55 , _tDcSource 6 , _cDcSource 6 , precision  , tprecision  , cprecision  , color_mask_sig_idx 3 , color_mask_oth_idx 5 , colorswap_p 0
  </p>

  
    <p>Legend</p>
    <table style="border-style: solid; border-width: 1px; border-color: #999999;">
    <tr><td style="background-color: #f7f77f;"> cp </td><td style="background-color: #f77ff7;">sig:1&nbsp;p%100.0</td><td style="background-color: #e77fe7;">sig:1&nbsp;p%87.5</td><td style="background-color: #d77fd7;">sig:1&nbsp;p%75.0</td><td style="background-color: #c77fc7;">sig:1&nbsp;p%62.5</td><td style="background-color: #b77fb7;">sig:1&nbsp;p%50.0</td><td style="background-color: #a77fa7;">sig:1&nbsp;p%37.5</td><td style="background-color: #977f97;">sig:1&nbsp;p%25.0</td><td style="background-color: #877f87;">sig:1&nbsp;p%12.5</td><td style="background-color: #787f78;">sig:0&nbsp;p%100.0</td><td style="background-color: #687f68;">sig:0&nbsp;p%87.5</td><td style="background-color: #587f58;">sig:0&nbsp;p%75.0</td><td style="background-color: #487f48; color: #ffffff;">sig:0&nbsp;p%62.5</td><td style="background-color: #387f38; color: #ffffff;">sig:0&nbsp;p%50.0</td><td style="background-color: #287f28; color: #ffffff;">sig:0&nbsp;p%37.5</td><td style="background-color: #187f18; color: #ffffff;">sig:0&nbsp;p%25.0</td><td style="background-color: #087f08; color: #ffffff;">sig:0&nbsp;p%12.5</td><td style="background-color: #4f4f4f; color: #ffffff;"> inactive </td></tr>
    <tr><td style="background-color: #ffff7f;"> cp </td><td style="background-color: #ff7fff;">sig:1&nbsp;p%100.0</td><td style="background-color: #ef7fef;">sig:1&nbsp;p%87.5</td><td style="background-color: #df7fdf;">sig:1&nbsp;p%75.0</td><td style="background-color: #cf7fcf;">sig:1&nbsp;p%62.5</td><td style="background-color: #bf7fbf;">sig:1&nbsp;p%50.0</td><td style="background-color: #af7faf;">sig:1&nbsp;p%37.5</td><td style="background-color: #9f7f9f;">sig:1&nbsp;p%25.0</td><td style="background-color: #8f7f8f;">sig:1&nbsp;p%12.5</td><td style="background-color: #807f80;">sig:0&nbsp;p%100.0</td><td style="background-color: #707f70;">sig:0&nbsp;p%87.5</td><td style="background-color: #607f60;">sig:0&nbsp;p%75.0</td><td style="background-color: #507f50;">sig:0&nbsp;p%62.5</td><td style="background-color: #407f40; color: #ffffff;">sig:0&nbsp;p%50.0</td><td style="background-color: #307f30; color: #ffffff;">sig:0&nbsp;p%37.5</td><td style="background-color: #207f20; color: #ffffff;">sig:0&nbsp;p%25.0</td><td style="background-color: #107f10; color: #ffffff;">sig:0&nbsp;p%12.5</td><td style="background-color: #4f4f4f; color: #ffffff;"> inactive </td></tr>
    <tr><td style="background-color: #cfcfcf;"> cp </td><td style="background-color: #cfcfcf;">sig:1&nbsp;p%100.0</td><td style="background-color: #c4c4c4;">sig:1&nbsp;p%87.5</td><td style="background-color: #bababa;">sig:1&nbsp;p%75.0</td><td style="background-color: #afafaf;">sig:1&nbsp;p%62.5</td><td style="background-color: #a4a4a4;">sig:1&nbsp;p%50.0</td><td style="background-color: #9a9a9a;">sig:1&nbsp;p%37.5</td><td style="background-color: #8f8f8f;">sig:1&nbsp;p%25.0</td><td style="background-color: #848484;">sig:1&nbsp;p%12.5</td><td style="background-color: #7a7a7a;">sig:0&nbsp;p%100.0</td><td style="background-color: #707070;">sig:0&nbsp;p%87.5</td><td style="background-color: #656565;">sig:0&nbsp;p%75.0</td><td style="background-color: #5a5a5a; color: #ffffff;">sig:0&nbsp;p%62.5</td><td style="background-color: #505050; color: #ffffff;">sig:0&nbsp;p%50.0</td><td style="background-color: #454545; color: #ffffff;">sig:0&nbsp;p%37.5</td><td style="background-color: #3a3a3a; color: #ffffff;">sig:0&nbsp;p%25.0</td><td style="background-color: #303030; color: #ffffff;">sig:0&nbsp;p%12.5</td><td style="background-color: #4f4f4f; color: #ffffff;"> inactive </td></tr>
    <tr><td style="background-color: #d4d4d4;"> cp </td><td style="background-color: #d4d4d4;">sig:1&nbsp;p%100.0</td><td style="background-color: #cacaca;">sig:1&nbsp;p%87.5</td><td style="background-color: #bfbfbf;">sig:1&nbsp;p%75.0</td><td style="background-color: #b4b4b4;">sig:1&nbsp;p%62.5</td><td style="background-color: #aaaaaa;">sig:1&nbsp;p%50.0</td><td style="background-color: #9f9f9f;">sig:1&nbsp;p%37.5</td><td style="background-color: #949494;">sig:1&nbsp;p%25.0</td><td style="background-color: #8a8a8a;">sig:1&nbsp;p%12.5</td><td style="background-color: #808080;">sig:0&nbsp;p%100.0</td><td style="background-color: #757575;">sig:0&nbsp;p%87.5</td><td style="background-color: #6a6a6a;">sig:0&nbsp;p%75.0</td><td style="background-color: #606060;">sig:0&nbsp;p%62.5</td><td style="background-color: #555555; color: #ffffff;">sig:0&nbsp;p%50.0</td><td style="background-color: #4a4a4a; color: #ffffff;">sig:0&nbsp;p%37.5</td><td style="background-color: #404040; color: #ffffff;">sig:0&nbsp;p%25.0</td><td style="background-color: #353535; color: #ffffff;">sig:0&nbsp;p%12.5</td><td style="background-color: #4f4f4f; color: #ffffff;"> inactive </td></tr>
</table>}
