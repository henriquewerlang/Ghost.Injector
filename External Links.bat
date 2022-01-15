mkdir Externals

cd Externals

mklink /j Delphi.Mock %1"\Delphi.Mock"
mklink /j DUnitX %1"\DUnitX"
mklink /j FastMM5 %1"\FastMM5"

cd..
