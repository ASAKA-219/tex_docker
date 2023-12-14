#!/usr/bin/env perl
$latex                       = 'uplatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error %O %S';
$latex_silent                = 'uplatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error %O %S';
$max_repeat                  = 6;

$bibtex                      = 'upbibtex';

$dvipdf                      = 'dvipdfmx %O -o %D %S';
$pdf_mode                    = 3;
$pvc_view_file_via_temporary = 0;
